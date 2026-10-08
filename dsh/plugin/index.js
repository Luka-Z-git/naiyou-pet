import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { initialActivity, reduceActivity, selectActivity, tokenSummary } from './activity.js';

export const inject = ['sessions', 'sessionProjections', 'agents'];

export function apply(ctx, config = {}) {
  // Resolve the same zod shipped with Harness, without fetching dependencies.
  const { z } = createRequire(path.resolve(process.argv[1]))('zod');
  ctx.sessionProjections.register({
    key: 'naiyouActivity', stateVersion: 1, stateSchema: z.any(),
    init: initialActivity, apply: reduceActivity,
  });
  const pluginDir = path.dirname(fileURLToPath(import.meta.url));
  const stateDir = config.stateDir || path.join(process.env.LOCALAPPDATA || pluginDir, 'DSH', 'Naiyou');
  fs.mkdirSync(stateDir, { recursive: true });
  const statePath = path.join(stateDir, `host-${process.pid}.json`);
  const streamPhases = new Map();
  const liveStatus = new Map();
  let child, stopped = false, debounce, failed = false, closedByUser = false, lastSnapshot;
  let nextLaunch = 0;

  function writeSnapshot(connected = true) {
    const rows = ctx.sessions.list().map(session => {
      const projected = ctx.sessionProjections.stateOf(session, 'naiyouActivity') ?? initialActivity();
      const status = liveStatus.get(session.id);
      // Restored sessions have no outstanding in-process approval request.
      const activity = { ...projected, active: status === 'running', approvals: status === 'running' ? projected.approvals : [] };
      const usageState = ctx.sessionProjections.stateOf(session, 'tokenUsage');
      const title = ctx.sessionProjections.stateOf(session, 'title');
      return { id: session.id, title: typeof title === 'string' ? title : '', activity,
        streamPhase: streamPhases.get(session.id), tokens: tokenSummary(usageState?.totals, usageState?.last != null || Object.values(usageState?.totals ?? {}).some(n => n > 0)) };
    });
    const state = { version: 2, connected, ownerPid: process.pid, updatedAt: Date.now(), ...selectActivity(rows) };
    persist(state);
    return state;
  }
  function persist(state) {
    const temp = statePath + '.tmp';
    fs.writeFileSync(temp, JSON.stringify(state), 'utf8');
    fs.renameSync(temp, statePath);
    lastSnapshot = state;
  }
  function refresh() {
    if (stopped) return;
    try { writeSnapshot(); failed = false; }
    catch (error) {
      if (!failed) ctx.logger.warn('奶邮状态刷新失败：' + String(error));
      failed = true;
    }
  }
  function queueRefresh() {
    if (!debounce && !stopped) debounce = setTimeout(() => { debounce = undefined; refresh(); }, 180);
  }
  function launch() {
    if (process.platform !== 'win32' || config.desktop === false || child || closedByUser || Date.now() < nextLaunch) return;
    const exe = path.join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
    const args = ['-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', path.join(pluginDir, 'desktop-pet.ps1'), '-StateFile', statePath, '-SpriteFile', path.join(pluginDir, 'naiyou-spritesheet.png')];
    const harnessExecutable = config.harnessExecutable || (/deepseek.*harness.*\.exe$/i.test(path.basename(process.execPath)) ? process.execPath : undefined);
    if (harnessExecutable) args.push('-HarnessExe', harnessExecutable);
    if (config.preferencesDir) args.push('-PreferencesDir', config.preferencesDir);
    if (config.previewOutput) args.push('-PreviewOutput', config.previewOutput);
    child = spawn(exe, args, { windowsHide: true, stdio: ['ignore', 'ignore', 'pipe'] });
    child.stderr.on('data', data => ctx.logger.warn('奶邮桌面窗：' + data.toString().slice(0, 600)));
    child.once('error', error => { ctx.logger.warn('奶邮桌面窗启动失败：' + String(error)); child = undefined; nextLaunch = Date.now() + 30000; });
    child.once('exit', code => { child = undefined; closedByUser = code === 0; nextLaunch = Date.now() + 30000; });
  }

  for (const agent of ctx.agents.list()) liveStatus.set(agent.session.id, agent.status);
  ctx.on('agent/status', ({ agent, status }) => { liveStatus.set(agent.session.id, status); if (status !== 'running') streamPhases.delete(agent.session.id); queueRefresh(); });
  ctx.on('agent/assistant-stream', ({ agent, frame }) => {
    if (frame.type === 'start') streamPhases.set(agent.session.id, 'thinking');
    if (frame.type === 'chunk') {
      const type = frame.chunk.type;
      if (/reason/i.test(type)) streamPhases.set(agent.session.id, 'thinking');
      else if (/text|content/i.test(type)) streamPhases.set(agent.session.id, 'writing');
    }
    queueRefresh();
  });
  ctx.on('session/event', (session, event) => {
    if (event.type === 'turn/start') liveStatus.set(session.id, 'running');
    if (event.type === 'turn/end') { liveStatus.set(session.id, 'idle'); streamPhases.delete(session.id); }
    queueRefresh();
  });
  ctx.on('session/created', queueRefresh);
  ctx.on('session/disposed', session => { liveStatus.delete(session.id); streamPhases.delete(session.id); queueRefresh(); });
  ctx.sessionProjections.onChanged((session, key) => { if (key === 'tokenUsage' || key === 'title') queueRefresh(); });
  ctx.effect(() => {
    refresh(); launch();
    const heartbeat = setInterval(() => { refresh(); launch(); }, 2000);
    return () => {
      stopped = true;
      clearInterval(heartbeat); clearTimeout(debounce);
      try { persist({ ...lastSnapshot, version: 2, ownerPid: process.pid, connected: false, updatedAt: Date.now() }); } catch {}
    };
  });
}
