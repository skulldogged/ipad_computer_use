'use strict';
const {encodeSequence} = require('./sequence');
const buttons = {left: 1, right: 2, middle: 4};
function encodeActions(actions) {
  if (!Array.isArray(actions) || !actions.length || actions.length > 128) throw Error('Use 1 to 128 actions');
  const records = [];
  let waitTotal = 0;
  const add = (...bytes) => {
    if (records.length >= 512) throw Error('Batch exceeds 512 input records');
    records.push(Buffer.from(bytes.map(n => n & 255)));
  };
  const integer = (n, limit, name) => {
    if (!Number.isInteger(n) || Math.abs(n) > limit) throw Error(`Invalid ${name}`);
    return n;
  };
  const absolute = (x, y, button = 0) => {
    integer(x, 32767, 'absolute x'); integer(y, 32767, 'absolute y');
    if (x < 0 || y < 0) throw Error('Absolute coordinates must be 0 to 32767');
    add(16 | button, x & 255, x >> 8, y & 255, y >> 8);
  };
  for (const action of actions) {
    if (!action || typeof action !== 'object') throw Error('Invalid action');
    switch (action.type) {
    case 'keys': {
      if (typeof action.sequence !== 'string') throw Error('keys needs sequence text');
      const bytes = Buffer.from(encodeSequence(action.sequence), 'hex');
      for (let i = 0; i < bytes.length; i += 2) add(1, bytes[i], bytes[i + 1], 0, 0);
      break;
    }
    case 'move': absolute(action.x, action.y); break;
    case 'click': {
      const button = buttons[action.button ?? 'left'];
      if (!button) throw Error('button must be left, right, or middle');
      absolute(action.x, action.y);
      absolute(action.x, action.y, button);
      absolute(action.x, action.y); break;
    }
    case 'drag': {
      const button = buttons[action.button ?? 'left'];
      if (!button) throw Error('button must be left, right, or middle');
      const {from, to} = action;
      if (!from || !to) throw Error('Absolute drag needs from and to');
      // Validate both endpoints before interpolation; retain the button across every report.
      for (const p of [from, to]) {
        integer(p.x, 32767, 'absolute x'); integer(p.y, 32767, 'absolute y');
        if (p.x < 0 || p.y < 0) throw Error('Absolute coordinates must be 0 to 32767');
      }
      absolute(from.x, from.y);
      absolute(from.x, from.y, button);
      const steps = Math.max(1, Math.ceil(Math.hypot(to.x-from.x, to.y-from.y) / 1024));
      for (let i=1; i<=steps; i++) absolute(Math.round(from.x+(to.x-from.x)*i/steps), Math.round(from.y+(to.y-from.y)*i/steps), button);
      absolute(to.x, to.y); break;
    }
    case 'scroll': add(24, integer(action.wheel, 127, 'wheel'), 0, 0, 0); break;
    case 'wait': {
      const ms = integer(action.ms, 10000, 'wait');
      if (ms < 0 || (waitTotal += ms) > 10000) throw Error('Total waits must be 0 to 10,000 ms');
      add(3, ms & 255, ms >> 8, 0, 0); break;
    }
    default: throw Error('Unknown action: ' + action.type);
    }
  }
  return Buffer.concat(records).toString('hex');
}
module.exports = {encodeActions};
