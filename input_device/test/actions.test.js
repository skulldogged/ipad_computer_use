const {test} = require('node:test');
const assert = require('node:assert/strict');
const {encodeActions} = require('../protocol/actions');
test('absolute clicks retain their position while pressing and releasing', () => {
  assert.equal(encodeActions([{type:'click',x:32767,y:16384}]), '10ff7f004011ff7f004010ff7f0040');
  for (const x of [-1,32768,1.5,NaN]) assert.throws(() => encodeActions([{type:'move',x,y:0}]));
});
test('absolute drag holds continuously and releases at the exact destination', () => {
  const b=Buffer.from(encodeActions([{type:'drag',from:{x:0,y:0},to:{x:32767,y:12345}}]),'hex');
  assert.equal(b[0],16);
  for(let i=5;i<b.length-5;i+=5) assert.equal(b[i],17);
  assert.equal(b.at(-5),16);
  assert.equal(b.readUInt16LE(b.length-4),32767);
  assert.equal(b.readUInt16LE(b.length-2),12345);
});
test('keyboard, absolute wheel and waits retain ordering',()=>{
  assert.equal(encodeActions([{type:'keys',sequence:'h'},{type:'scroll',wheel:-3},{type:'wait',ms:300}]),'010068000018fd000000032c010000');
  for(const a of [[],[{type:'move',dx:1,dy:1}],[{type:'scroll',wheel:128}],[{type:'wait',ms:-1}],[{type:'keys',sequence:'a'.repeat(513)}]]) assert.throws(()=>encodeActions(a));
});
