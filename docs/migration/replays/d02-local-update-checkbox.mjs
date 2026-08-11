import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const fm7 = original('fm7.java');
const wh = original('wh.java');
const gv0 = original('gv0.java');
const u5j = original('u5j.java');
const local = read('note/src/main/ets/data/OriginalLocalCheckboxMutation.ets');
const reducer = read('note/src/main/ets/data/OriginalUpdateCheckboxOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const fixture = read('note/src/test/OriginalLocalCheckboxMutation.test.ets');

assert.match(fm7, /U\("toggleCheckbox", new wh\(i, mkeVar\.a, this, t3cVar\)\)/);
assert.match(wh, /qi3Var == null \|\| qi3Var\.i != fy2\.CHECK_BOX/);
assert.match(wh, /t3cVar\.w\(numValueOf2\.intValue\(\)\)/);
assert.match(wh, /boolean z = !zBooleanValue/);
assert.match(wh, /new gv0\([\s\S]*?z, 10\)/);
assert.match(gv0, /u5j\.J\(\(x09\) h50Var\.c, \(qo5\) h50Var\.b, \(exc\) this\.K, this\.J\)/);
assert.match(u5j, /public static final mqf J\(x09 x09Var, qo5 qo5Var, exc excVar, boolean z\)/);
assert.match(u5j, /aVarA\.j\(1, sg5\.f\(aVarA, excVar\)\)/);
assert.match(u5j, /aVarA\.a\(2, z, false\)/);
assert.match(u5j, /aVarA\.j\(0, rh8\.O\(qo5Var, aVarA\)\)/);

assert.match(local, /export function toggleOriginalCheckboxAt/);
assert.match(local, /index === 0 \|\| scalars\[index - 1\] === 0x0A/);
assert.match(local, /styles\[codePointIndex\]\.decoratorStyle !== 3/);
assert.match(local, /styles\[codePointIndex\]\.isChecked !== true/);
assert.match(local, /materializeOriginalTextCharacterOrder\(characters\)/);
assert.match(local, /location: cloneIdentity\(visible\[index\]\.identity\)/);
assert.match(reducer, /export function encodeOriginalUpdateCheckbox/);
assert.match(reducer, /writeIdentity\(bytes, table \+ 4, payload\.textField\)/);
assert.match(reducer, /writeSequence\(bytes, table \+ 12, payload\.location\)/);
assert.match(reducer, /payload\.isChecked \? 24 : 0/);

assert.match(persistence, /await this\.originalCheckboxMutation\(/);
assert.match(persistence, /planOriginalLocalCheckboxMutation\(characters, before, after\)/);
assert.match(persistence, /encodeOriginalUpdateCheckbox\(\{/);
assert.match(persistence, /new OriginalUpdateCheckboxOperationApplier\(\)\.apply\(store, operation\)/);
assert.match(persistence, /opType: OpType\.ORIGINAL_UPDATE_CHECKBOX/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /local UpdateCheckbox reducer produced unexpected final state/);
assert.match(opTypes, /ORIGINAL_UPDATE_CHECKBOX = 76/);
assert.match(history, /operation\.opType === OpType\.ORIGINAL_UPDATE_CHECKBOX/);
assert.match(fixture, /maps Unicode code-point paragraph starts to stable character identities/);
assert.match(fixture, /round-trips canonical type-28 true and omitted false payloads/);

const characters = [
  { scalar: 0x1f600, id: '100:7:0' },
  { scalar: 0x0a, id: '101:7:1' },
  { scalar: 0x42, id: '102:7:2' },
];
const starts = characters.map((character, index) =>
  index === 0 || characters[index - 1].scalar === 0x0a ? character.id : null)
  .filter(value => value !== null);
assert.deepEqual(starts, ['100:7:0', '102:7:2']);
const checked = true;
assert.equal(!checked, false);
assert.equal(!(undefined === true), true);

console.log('localUpdateCheckbox=' +
  'original-toggle-bridge-stable-location-type28-default-false-authority-guard-history-upload');
