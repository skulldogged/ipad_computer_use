const {test} = require('node:test');
const assert = require('node:assert/strict');
const {compileHighLevelActions} = require('../high_level_actions');
test('absolute coordinates require neither a profile nor a starting pointer', () => {
  assert.deepEqual(compileHighLevelActions({coordinateSpace:{width:1180,height:820},actions:[
    {type:'move_to',x:590,y:410},{type:'click',x:1180,y:0},
    {type:'drag',from:{x:0,y:820},to:{x:1180,y:0}}
  ]}), [
    {type:'move',x:16384,y:16384},
    {type:'click',button:'left',x:32767,y:0},
    {type:'drag',button:'left',from:{x:0,y:32767},to:{x:32767,y:0}}
  ]);
  assert.throws(() => compileHighLevelActions({coordinateSpace:{width:1180,height:820},actions:[{type:'move_to',x:-1,y:0}]}),/inside/);
});

test('compiles text and key chords to keyboard sequences', () => {
  assert.deepEqual(compileHighLevelActions({actions: [
    {type: 'type_text', text: 'hello'},
    {type: 'press', keys: {modifiers: ['cmd'], key: 'space'}},
    {type: 'wait', ms: 250}
  ]}, null), [
    {type: 'keys', sequence: 'hello'},
    {type: 'keys', sequence: '{CMD+SPACE}'},
    {type: 'wait', ms: 250}
  ]);
});

test('rejects guessed key chord shapes with a prescriptive error', () => {
  assert.throws(() => compileHighLevelActions({
    actions: [{type: 'press', keys: ['cmd', 'space']}]
  }, null), /press\.keys must be an object/);
  assert.throws(() => compileHighLevelActions({
    actions: [{type: 'press', key: 'space', modifiers: ['cmd']}]
  }, null), /press\.keys must be an object/);
});

test('rejects relative movement and coordinate-free clicks',()=>{
  assert.throws(()=>compileHighLevelActions({actions:[{type:'move_by',dx:1,dy:1}]}),/Unknown/);
  assert.throws(()=>compileHighLevelActions({actions:[{type:'click'}]}),/finite/);
});
