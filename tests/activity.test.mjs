import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initialActivity, reduceActivity, selectActivity, tokenSummary } from '../dsh/plugin/activity.js';
const event = (type, data, time=100) => ({type,data,time});
const row = (id,activity,tokens=null) => ({id,title:id,activity,tokens});
test('approval wins over another busy or newer finished session, and multiple requests survive independent decisions', () => {
  let a=reduceActivity(initialActivity(), event('turn/start',{}));
  a=reduceActivity(a,event('approval/asked',{id:'a1',toolName:'shell'}));
  a=reduceActivity(a,event('approval/asked',{id:'a2',toolName:'edit'}));
  let b=reduceActivity(initialActivity(),event('turn/start',{},300));
  const selected=selectActivity([row('a',a),row('b',b)],400);
  assert.equal(selected.sessionId,'a'); assert.equal(selected.phase,'approval'); assert.equal(selected.pending.length,2);
  a=reduceActivity(a,event('approval/decided',{id:'a1'}));
  assert.equal(selectActivity([row('a',a)]).pending[0].id,'a2');
  a=reduceActivity(a,event('turn/end',{}));
  assert.equal(selectActivity([row('a',a),row('b',b)],400).sessionId,'b');
  assert.equal(a.approvals.length,0);
});
test('parallel tool completion leaves the other tool visible and does not export arguments or outputs', () => {
  let a=reduceActivity(initialActivity(),event('turn/start',{}));
  a=reduceActivity(a,event('tool/call',{callId:'read',name:'read_file',arguments:{password:'do-not-export'}}));
  a=reduceActivity(a,event('tool/call',{callId:'shell',name:'shell',arguments:{command:'do-not-export'}}));
  assert.match(selectActivity([row('a',a)]).action,/读取文件/);
  a=reduceActivity(a,event('tool/result',{message:{source:{kind:'tool',callId:'read'},content:'do-not-export'}}));
  assert.match(selectActivity([row('a',a)]).action,/执行命令/);
  assert.ok(!JSON.stringify(a).includes('do-not-export'));
});
test('provider token buckets include cache exactly once and distinguish missing usage from reported zero', () => {
  const totals={uncachedInputTokens:100,cacheReadTokens:60,cacheWriteTokens:20,outputTokens:50};
  assert.deepEqual(tokenSummary(totals,true),{input:180,output:50,cacheRead:60,cacheWrite:20,uncachedInput:100,total:230});
  assert.equal(tokenSummary(totals,false),null);
  assert.equal(tokenSummary({uncachedInputTokens:0,outputTokens:0},true).total,0);
});
test('completion expires and reply streaming produces a specific activity label', () => {
  let a=reduceActivity(initialActivity(),event('turn/start',{},100));
  assert.equal(selectActivity([{...row('a',a),streamPhase:'writing'}],200).action,'正在生成回复…');
  a=reduceActivity(a,event('turn/end',{},300));
  assert.equal(selectActivity([row('a',a)],400).action,'完成啦！');
  assert.equal(selectActivity([row('a',a)],13000).phase,'idle');
});
test('cancelled, blocked, and failed tasks are not reported as completed', () => {
  for (const [kind,label] of [['aborted','任务已取消'],['blocked','等待新的输入'],['error','任务已停止，请查看 Harness']]) {
    const a=reduceActivity(initialActivity(),event('turn/end',{reason:{kind}},300));
    assert.equal(selectActivity([row('a',a)],400).action,label);
  }
});
