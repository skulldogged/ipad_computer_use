'use strict';

const buttons = new Set(['left', 'right', 'middle']);
const modifiers = new Set(['ctrl', 'shift', 'alt', 'cmd']);
const namedKeys = new Set(['enter', 'return', 'escape', 'esc', 'backspace', 'tab', 'space',
  'delete', 'home', 'end', 'pageup', 'pagedown', 'right', 'left', 'down', 'up',
  'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12']);

function finite(value, name) {
  if (!Number.isFinite(value)) throw Error(`${name} must be a finite number`);
  return value;
}

function integer(value, name, limit) {
  if (!Number.isInteger(value) || Math.abs(value) > limit) throw Error(`${name} must be an integer from ${-limit} to ${limit}`);
  return value;
}

function point(value, name) {
  if (!value || typeof value !== 'object') throw Error(`${name} must be a point`);
  return {x: finite(value.x, `${name}.x`), y: finite(value.y, `${name}.y`)};
}

function keyChord(value) {
  if (!value || Array.isArray(value) || typeof value !== 'object') {
    throw Error('press.keys must be an object like {"key":"space","modifiers":["cmd"]}; arrays are not accepted');
  }
  if (typeof value.key !== 'string') throw Error('press.keys.key must be a string');
  const key = value.key.trim().toLowerCase();
  if (!(key.length === 1 || namedKeys.has(key))) throw Error('press.keys.key must be a printable key or supported named key');
  const parts = [];
  for (const modifier of value.modifiers || []) {
    const name = String(modifier).toLowerCase();
    if (!modifiers.has(name)) throw Error('press.keys.modifiers can only include ctrl, shift, alt, or cmd');
    parts.push(name === 'alt' ? 'OPTION' : name.toUpperCase());
  }
  parts.push(key.length === 1 ? key.toUpperCase() : key.toUpperCase());
  return `{${parts.join('+')}}`;
}

function compileHighLevelActions(body) {
  if (!body || typeof body !== 'object') throw Error('Request body must be an object');
  if (!Array.isArray(body.actions) || !body.actions.length || body.actions.length > 128) throw Error('Use 1 to 128 actions');
  const coordinateSpace = body.coordinateSpace;
  const scale = p => {
    const width = finite(coordinateSpace?.width, 'coordinateSpace.width');
    const height = finite(coordinateSpace?.height, 'coordinateSpace.height');
    if (width <= 0 || height <= 0) throw Error('coordinateSpace dimensions must be positive');
    if (!['screen_pixels', 'ui_points'].includes(coordinateSpace?.units || 'screen_pixels')) throw Error('coordinateSpace.units must be screen_pixels or ui_points');
    if (p.x < 0 || p.x > width || p.y < 0 || p.y > height) throw Error('Point must be inside coordinateSpace');
    return {x: Math.round(p.x / width * 32767), y: Math.round(p.y / height * 32767)};
  };
  const output = [];
  for (const action of body.actions) {
    if (!action || typeof action !== 'object') throw Error('Invalid action');
    switch (action.type) {
    case 'type_text':
      if (typeof action.text !== 'string') throw Error('type_text.text must be text');
      output.push({type:'keys', sequence:action.text}); break;
    case 'press': output.push({type:'keys', sequence:keyChord(action.keys)}); break;
    case 'wait': output.push({type:'wait', ms:integer(action.ms,'wait.ms',10000)}); break;
    case 'scroll': output.push({type:'scroll', wheel:integer(action.dy ?? action.wheel,'scroll.dy',127)}); break;
    case 'move_to': output.push({type:'move', ...scale(point(action,'move_to'))}); break;
    case 'click': {
      const button=action.button || 'left';
      if (!buttons.has(button)) throw Error('click.button must be left, right, or middle');
      output.push({type:'click',button,...scale(point(action,'click'))}); break;
    }
    case 'drag': {
      const button=action.button || 'left';
      if (!buttons.has(button)) throw Error('drag.button must be left, right, or middle');
      output.push({type:'drag',button,from:scale(point(action.from,'drag.from')),to:scale(point(action.to,'drag.to'))}); break;
    }
    default: throw Error('Unknown computer-use action: '+action.type);
    }
  }
  return output;
}
module.exports = {compileHighLevelActions};
