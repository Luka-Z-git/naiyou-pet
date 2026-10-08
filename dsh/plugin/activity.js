// Only labels and provider-reported counters leave the Harness host.
export function initialActivity() {
  return { active: false, phase: 'idle', tools: [], approvals: [], updatedAt: 0, endedAt: 0 };
}
export function reduceActivity(state, event) {
  const d = event.data ?? {};
  const update = patch => ({ ...state, ...patch, updatedAt: event.time });
  switch (event.type) {
    case 'turn/start': return update({ active: true, phase: 'thinking', tools: [], approvals: [] });
    case 'step/start': return update({ active: true, phase: 'thinking' });
    case 'tool/call': return update({ active: true, phase: 'tool', tools: [...state.tools.filter(t => t.callId !== d.callId), { callId: d.callId, name: clean(d.name, 50) }] });
    case 'tool/result': {
      const tools = state.tools.filter(t => t.callId !== d.message?.source?.callId);
      return update({ tools, phase: tools.length ? 'tool' : 'thinking' });
    }
    case 'approval/asked': return update({ approvals: [...state.approvals.filter(a => a.id !== d.id), { id: d.id, toolName: clean(d.toolName, 50) }] });
    case 'approval/decided': return update({ approvals: state.approvals.filter(a => a.id !== d.id) });
    case 'assistant/message': return update({ phase: state.tools.length ? 'tool' : 'writing' });
    case 'turn/end': {
      const phase = ({ error: 'error', aborted: 'cancelled', blocked: 'blocked', 'max-tokens': 'limited' })[d.reason?.kind] ?? 'done';
      return update({ active: false, phase, tools: [], approvals: [], endedAt: event.time });
    }
    default: return state;
  }
}
export function clean(value, max = 70) {
  return typeof value === 'string' ? value.replace(/[\x00-\x1f\x7f]/g, ' ').slice(0, max) : '';
}
export function toolLabel(name) {
  if (/read|view|cat/i.test(name)) return '读取文件';
  if (/write|edit|patch|replace/i.test(name)) return '修改文件';
  if (/search|grep|glob|find|list/i.test(name)) return '搜索资料';
  if (/shell|bash|exec|terminal|command/i.test(name)) return '执行命令';
  if (/web|fetch|browse/i.test(name)) return '访问网页';
  return '调用工具';
}
export function tokenSummary(totals, seen) {
  if (!totals || !seen) return null;
  const number = key => Number.isSafeInteger(totals[key]) && totals[key] >= 0 ? totals[key] : 0;
  const uncachedInput = number('uncachedInputTokens');
  const cacheRead = number('cacheReadTokens');
  const cacheWrite = number('cacheWriteTokens');
  const input = uncachedInput + cacheRead + cacheWrite;
  const output = number('outputTokens');
  return { input, output, cacheRead, cacheWrite, uncachedInput, total: input + output };
}
export function selectActivity(rows, now = Date.now()) {
  const sorted = [...rows].sort((a, b) => {
    const rank = r => r.activity.approvals.length ? 3 : r.activity.active ? 2 : 1;
    return rank(b) - rank(a) || b.activity.updatedAt - a.activity.updatedAt;
  });
  const row = sorted[0];
  const pending = sorted.flatMap(r => r.activity.approvals.map(a => ({ ...a, sessionId: r.id, title: r.title })));
  if (!row) return { phase: 'idle', action: '陪你一起工作', title: 'DeepSeek Harness', tokens: null, pending: [], runningCount: 0 };
  const s = row.activity;
  let phase = s.phase;
  let action = '陪你一起工作';
  if (s.approvals.length) {
    phase = 'approval';
    action = '需要你批准：' + (s.approvals[0].toolName || '工具调用');
  } else if (s.active) {
    phase = row.streamPhase ?? s.phase;
    if (s.tools.length) {
      phase = 'tool';
      action = toolLabel(s.tools[0].name) + ' · ' + s.tools[0].name;
      if (s.tools.length > 1) action += ' +' + (s.tools.length - 1);
    } else { phase = phase === 'writing' ? 'writing' : 'thinking'; action = phase === 'writing' ? '正在生成回复…' : '正在思考…'; }
  } else if (s.phase === 'done' && now - s.endedAt < 12000) action = '完成啦！';
  else if (s.phase === 'error') action = '任务已停止，请查看 Harness';
  else if (s.phase === 'cancelled' && now - s.endedAt < 12000) action = '任务已取消';
  else if (s.phase === 'blocked') action = '等待新的输入';
  else if (s.phase === 'limited') action = '达到输出限制，请查看 Harness';
  else phase = 'idle';
  return { phase, action, title: clean(row.title) || '会话 ' + row.id.slice(0, 8), sessionId: row.id, tokens: row.tokens, pending, runningCount: sorted.filter(r => r.activity.active).length };
}
