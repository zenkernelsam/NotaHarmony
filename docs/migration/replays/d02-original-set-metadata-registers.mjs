import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { assertDatabaseVersionAtLeast } from './support/database-version.mjs';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const normalize = value => value.replaceAll('\r\n', '\n');
const readRepo = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const readOriginal = name => normalize(fs.readFileSync(path.join(originalRoot, name), 'utf8'));

const l2d = readOriginal('l2d.java');
const xj2 = readOriginal('xj2.java');
const rz1 = readOriginal('rz1.java');
const fqb = readOriginal('fqb.java');
const so5 = readOriginal('so5.java');
const v69 = readOriginal('v69.java');
const a79 = readOriginal('a79.java');
const u5j = readOriginal('u5j.java');
const tv6 = readOriginal('tv6.java');
const dz0 = readOriginal('dz0.java');
const x82 = readOriginal('x82.java');
const z5c = readOriginal('z5c.java');
const yo7 = readOriginal('yo7.java');
const jc5 = readOriginal('jc5.java');

const schema = readRepo('note/src/main/ets/data/DatabaseHelper.ets');
const manager = readRepo('note/src/main/ets/data/DatabaseManager.ets');
const production = readRepo('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const policy = readRepo('note/src/main/ets/core/model/OriginalNoteMetadataPolicy.ets');
const bootstrap = readRepo(
  'note/src/main/ets/data/OriginalBlankNoteBootstrapPersistence.ets');
const fixture = readRepo('note/src/test/SyncedOperationInbox.test.ets');
const policyFixture = readRepo('note/src/test/OriginalNoteMetadataPolicy.test.ets');
const databaseFixture = readRepo('note/src/test/DatabaseHelper.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

let total = 0;
let failed = 0;

function check(name, condition) {
  total++;
  if (!condition) {
    failed++;
    console.error(`FAIL: ${name}`);
    return;
  }
  console.log(`PASS: ${name}`);
}

function templateConstant(source, name) {
  const match = source.match(new RegExp(
    'export const ' + name + ': string = `([\\s\\S]*?)`;'));
  assert.ok(match, `missing template constant ${name}`);
  return match[1];
}

function compareIdentity(left, right) {
  if (left.timestamp !== right.timestamp) {
    return left.timestamp < right.timestamp ? -1 : 1;
  }
  if (left.siteId === right.siteId) return 0;
  return left.siteId < right.siteId ? -1 : 1;
}

function clone(value) {
  return structuredClone(value);
}

function equalValue(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

const fields = [
  'title', 'background', 'handwritingLanguage', 'alignTextToLines',
  'defaultFontFamily', 'defaultFontSize', 'layoutMode', 'blockWrapSupport',
];

function validLanguage(value) {
  if (value === null) return true;
  const prefix = value.split('_', 1)[0];
  return new Set(['en', 'he', 'iw', 'id', 'in', 'yi', 'ji', 'zh']).has(prefix);
}

function validatePatch(patch) {
  if (patch.background?.present && patch.background.value?.pdf &&
    patch.background.value.pdf.pagesConsumed !== 1) {
    throw new Error('pdf page count');
  }
  if (patch.handwritingLanguage?.present &&
    !validLanguage(patch.handwritingLanguage.value)) {
    throw new Error('language');
  }
  if (patch.defaultFontFamily?.present &&
    patch.defaultFontFamily.value.length > 30) {
    throw new Error('font family');
  }
  if (patch.defaultFontSize?.present &&
    (!Number.isFinite(patch.defaultFontSize.value) || patch.defaultFontSize.value <= 0)) {
    throw new Error('font size');
  }
  if (patch.layoutMode?.present && ![0, 1].includes(patch.layoutMode.value)) {
    throw new Error('layout');
  }
  if (patch.blockWrapSupport?.present &&
    ![0, 1, 2].includes(patch.blockWrapSupport.value)) {
    throw new Error('wrap');
  }
}

function applyPatch(state, identity, patch) {
  validatePatch(patch);
  const decisions = new Map();
  for (const field of fields) {
    const setter = patch[field];
    if (!setter?.present) continue;
    const winner = state.winners[field];
    if (winner === undefined) {
      decisions.set(field, true);
      continue;
    }
    const compared = compareIdentity(identity, winner);
    if (compared < 0) {
      decisions.set(field, false);
      continue;
    }
    if (compared === 0) {
      if (!equalValue(winner.value, setter.value)) {
        throw new Error(`${field} identity conflict`);
      }
      decisions.set(field, false);
      continue;
    }
    decisions.set(field, true);
  }
  if (decisions.get('background') && patch.background.value?.pdf) {
    state.assets.add(patch.background.value.pdf.assetHash);
  }
  let changed = false;
  for (const [field, apply] of decisions) {
    if (!apply) continue;
    state.winners[field] = {
      timestamp: identity.timestamp, siteId: identity.siteId,
      value: clone(patch[field].value),
    };
    changed = true;
  }
  if (changed) state.revision++;
  return changed;
}

check('original validates title, template PDF page count, font size and family length',
  l2d.includes('Template PDFs can only consume (have) one page') &&
    l2d.includes('fM.floatValue() <= 0.0f') && l2d.includes('strL.length() > 30'));
check('original handwriting validation uses the exact prefix before underscore and ISO list',
  l2d.includes('new String[]{"_"}') && l2d.includes('Locale.getISOLanguages()') &&
    l2d.includes('x90.w(iSOLanguages, str)'));
check('original table exposes wrapper fields 0 through 2 and scalar-presence fields 3 through 7',
  l2d.includes('c(4)') && l2d.includes('c(6)') && l2d.includes('c(8)') &&
    l2d.includes('c(10)') && l2d.includes('c(12)') && l2d.includes('c(14)') &&
    l2d.includes('c(16)') && l2d.includes('c(18)'));
check('original encoder writes all eight SET_METADATA fields in FlatBuffer order',
  xj2.includes('aVar.C(8)') && xj2.includes('aVar.h(2, numValueOf3.intValue())') &&
    xj2.includes('aVar.a(3, zBooleanValue, false)') &&
    xj2.includes('aVar.h(4, numValueOf4.intValue())') &&
    xj2.includes('aVar.d(5, f2.floatValue(), 0.0d)') &&
    xj2.includes('aVar.c(6, tv6Var.I, 0)') &&
    xj2.includes('aVar.c(7, dz0Var.b(), 0)'));
check('original handwriting wrapper preserves explicit null while scalar helpers skip absence',
  rz1.includes('((fqb) v1bVar.get()).c(uq9Var, z2dVar.j());') &&
    rz1.includes('if (obj == null)') && rz1.includes('return false;'));
check('original applies title background and six metadata values to independent registers',
  ['titleRegister', 'pageBackgroundRegister', 'handwritingLanguageRegister',
    'alignTextToLinesRegister', 'defaultFontFamilyRegister', 'defaultFontSizeRegister',
    'layoutModeRegister', 'blockWrapSupportRegister']
    .every(name => v69.includes(name)));
check('original register replacement is strict greater unsigned timestamp then site',
  fqb.includes('so5.a(qo5VarL, qo5Var) > 0') &&
    so5.includes('Integer.compareUnsigned(qo5Var.d(), qo5Var2.d())') &&
    so5.includes('qo5Var.c() & 65535'));
check('original NoteImpl persists six metadata registers and snapshot serialization emits them',
  a79.includes('defaultFontFamilyRegister') && a79.includes('defaultFontSizeRegister') &&
    a79.includes('alignTextToLinesRegister') && a79.includes('layoutModeRegister') &&
    a79.includes('blockWrapSupportRegister') && a79.includes('handwritingLanguageRegister') &&
    u5j.includes('xj2.v(yc6Var, fl6VarArr[6])') &&
    u5j.includes('xj2.v(a79Var.w, fl6VarArr[3])') &&
    u5j.includes('xj2.v(a79Var.v, fl6VarArr[2])') &&
    u5j.includes('xj2.v(a79Var.u, fl6VarArr[1])'));
check('original enum bytes are PAGED 0 PAGELESS 1 and wrapping 0 1 2',
  tv6.includes('PAGED((byte) 0)') && tv6.includes('PAGELESS((byte) 1)') &&
    dz0.includes('WRAP_ENABLED((byte) 0)') &&
    dz0.includes('WRAP_DISABLED((byte) 1)') &&
    dz0.includes('LEGACY_WRAP_ENABLED((byte) 2)'));
check('original has concrete layout align and handwriting consumers',
  x82.includes('a79Var.c() != tv6.PAGELESS') &&
    z5c.includes('a79Var.c() == tv6.PAGELESS') &&
    yo7.includes('xj2.v(a79Var2.w, a79.M[3])') &&
    jc5.includes('xj2.v(((a79) x09Var).A, a79.M[6])'));

check('Harmony database version and migration advance to v65',
  assertDatabaseVersionAtLeast(schema, 65) >= 65 && schema.includes('65: ['));

const ddlNames = [
  'DDL_ORIGINAL_NOTE_HANDWRITING_LANGUAGE_WINNER',
  'DDL_ORIGINAL_NOTE_ALIGN_TEXT_TO_LINES_WINNER',
  'DDL_ORIGINAL_NOTE_DEFAULT_FONT_FAMILY_WINNER',
  'DDL_ORIGINAL_NOTE_DEFAULT_FONT_SIZE_WINNER',
  'DDL_ORIGINAL_NOTE_LAYOUT_MODE_WINNER',
  'DDL_ORIGINAL_NOTE_BLOCK_WRAP_SUPPORT_WINNER',
];
const ddl = ddlNames.map(name => templateConstant(schema, name));
const db = new DatabaseSync(':memory:');
db.exec('PRAGMA foreign_keys=ON; CREATE TABLE note_meta (id TEXT PRIMARY KEY);');
for (const statement of ddl) db.exec(statement);
db.exec(`INSERT INTO note_meta VALUES('n');
  INSERT INTO original_note_handwriting_language_winner VALUES('n',1,1,NULL);
  INSERT INTO original_note_align_text_to_lines_winner VALUES('n',1,1,1);
  INSERT INTO original_note_default_font_family_winner VALUES('n',1,1,'Noto Sans');
  INSERT INTO original_note_default_font_size_winner VALUES('n',1,1,17);
  INSERT INTO original_note_layout_mode_winner VALUES('n',1,1,1);
  INSERT INTO original_note_block_wrap_support_winner VALUES('n',1,1,2);`);
check('v65 creates six independent winner tables with nullable handwriting',
  db.prepare('SELECT handwriting_language AS value FROM ' +
    'original_note_handwriting_language_winner').get().value === null &&
    ddl.every(statement => statement.includes('PRIMARY KEY')));
const snapshotSql = `SELECT
  h.note_id AS handwriting_winner, h.handwriting_language,
  a.note_id AS align_winner, a.align_text_to_lines,
  f.note_id AS family_winner, f.default_font_family,
  s.note_id AS size_winner, s.default_font_size,
  l.note_id AS layout_winner, l.layout_mode,
  w.note_id AS wrap_winner, w.block_wrap_support
FROM (SELECT ? AS note_id) target
LEFT JOIN original_note_handwriting_language_winner h ON h.note_id = target.note_id
LEFT JOIN original_note_align_text_to_lines_winner a ON a.note_id = target.note_id
LEFT JOIN original_note_default_font_family_winner f ON f.note_id = target.note_id
LEFT JOIN original_note_default_font_size_winner s ON s.note_id = target.note_id
LEFT JOIN original_note_layout_mode_winner l ON l.note_id = target.note_id
LEFT JOIN original_note_block_wrap_support_winner w ON w.note_id = target.note_id`;
const snapshot = db.prepare(snapshotSql).get('n');
const absentSnapshot = db.prepare(snapshotSql).get('missing');
check('single-statement readback preserves explicit-null handwriting and absent rows',
  snapshot.handwriting_winner === 'n' && snapshot.handwriting_language === null &&
    snapshot.layout_mode === 1 && snapshot.block_wrap_support === 2 &&
    absentSnapshot.handwriting_winner === null && absentSnapshot.layout_winner === null);
check('v65 constrains boolean and enum domains', (() => {
  assert.throws(() => db.exec(
    "UPDATE original_note_align_text_to_lines_winner SET align_text_to_lines=2"));
  assert.throws(() => db.exec(
    "UPDATE original_note_layout_mode_winner SET layout_mode=2"));
  assert.throws(() => db.exec(
    "UPDATE original_note_block_wrap_support_winner SET block_wrap_support=3"));
  return true;
})());
db.exec("DELETE FROM note_meta WHERE id='n'");
check('all six v65 winner tables cascade when their note is deleted',
  ddl.map(statement => statement.match(/CREATE TABLE IF NOT EXISTS ([a-z_]+)/)[1])
    .every(table => db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).get().count === 0));
check('latest schema initialization includes every new winner table',
  ddlNames.every(name => manager.includes(name)));

const state = { winners: {}, revision: 0, assets: new Set() };
const first = {
  title: { present: true, value: 'Imported' },
  background: { present: true, value: { pdf: { pagesConsumed: 1, assetHash: 'asset-a' } } },
  handwritingLanguage: { present: true, value: 'en_US' },
  alignTextToLines: { present: true, value: true },
  defaultFontFamily: { present: true, value: 'Noto Sans' },
  defaultFontSize: { present: true, value: 24 },
  layoutMode: { present: true, value: 1 },
  blockWrapSupport: { present: true, value: 2 },
};
check('independent model applies all eight fields and advances one revision',
  applyPatch(state, { timestamp: 10, siteId: 2 }, first) &&
    Object.keys(state.winners).length === 8 && state.revision === 1 &&
    state.assets.has('asset-a'));
check('strictly stale SET_METADATA is a complete no-op including PDF asset references',
  !applyPatch(state, { timestamp: 9, siteId: 65535 }, {
    background: { present: true, value: { pdf: { pagesConsumed: 1, assetHash: 'stale' } } },
    layoutMode: { present: true, value: 0 },
  }) && state.revision === 1 && !state.assets.has('stale'));
state.winners.alignTextToLines = { timestamp: 20, siteId: 1, value: true };
check('one operation can update newer fields while an independently newer register stays unchanged',
  applyPatch(state, { timestamp: 15, siteId: 1 }, {
    handwritingLanguage: { present: true, value: null },
    alignTextToLines: { present: true, value: false },
    defaultFontFamily: { present: true, value: 'Serif' },
  }) && state.winners.handwritingLanguage.value === null &&
    state.winners.alignTextToLines.value === true &&
    state.winners.defaultFontFamily.value === 'Serif' && state.revision === 2);
check('same identity and same complete value is idempotent',
  !applyPatch(state, { timestamp: 15, siteId: 1 }, {
    handwritingLanguage: { present: true, value: null },
    defaultFontFamily: { present: true, value: 'Serif' },
  }) && state.revision === 2);
const beforeConflict = clone({ winners: state.winners, revision: state.revision,
  assets: [...state.assets] });
state.winners.blockWrapSupport = { timestamp: 30, siteId: 4, value: 1 };
const conflictBaseline = clone({ winners: state.winners, revision: state.revision,
  assets: [...state.assets] });
check('same identity different value rejects the whole mixed patch before any write', (() => {
  assert.throws(() => applyPatch(state, { timestamp: 30, siteId: 4 }, {
    title: { present: true, value: 'Must not commit' },
    background: { present: true,
      value: { pdf: { pagesConsumed: 1, assetHash: 'must-not-attach' } } },
    layoutMode: { present: true, value: 0 },
    blockWrapSupport: { present: true, value: 2 },
  }), /identity conflict/);
  return equalValue({ winners: state.winners, revision: state.revision,
    assets: [...state.assets] }, conflictBaseline) && !state.assets.has('must-not-attach');
})());
check('site id breaks equal-timestamp ties as an unsigned strict-greater clock',
  applyPatch(state, { timestamp: 30, siteId: 5 }, {
    blockWrapSupport: { present: true, value: 2 },
  }) && state.winners.blockWrapSupport.siteId === 5);
check('explicit-null handwriting remains distinguishable from an absent setter',
  state.winners.handwritingLanguage.value === null &&
    applyPatch(state, { timestamp: 31, siteId: 1 }, {
      layoutMode: { present: true, value: 0 },
    }) && state.winners.handwritingLanguage.value === null);
check('invalid language family size enum and PDF page count fail before mutation', (() => {
  const invalids = [
    { handwritingLanguage: { present: true, value: 'zz_US' } },
    { defaultFontFamily: { present: true, value: 'x'.repeat(31) } },
    { defaultFontSize: { present: true, value: Number.POSITIVE_INFINITY } },
    { layoutMode: { present: true, value: 2 } },
    { blockWrapSupport: { present: true, value: 3 } },
    { background: { present: true, value: { pdf: { pagesConsumed: 2, assetHash: 'bad' } } } },
  ];
  const baseline = clone({ winners: state.winners, revision: state.revision,
    assets: [...state.assets] });
  for (const invalid of invalids) {
    assert.throws(() => applyPatch(state, { timestamp: 40, siteId: 1 }, invalid));
  }
  return equalValue({ winners: state.winners, revision: state.revision,
    assets: [...state.assets] }, baseline);
})());
check('model conflict setup did not accidentally alter the earlier baseline before conflict',
  beforeConflict.revision === 2 && beforeConflict.assets.includes('asset-a'));

check('Harmony decodes wrapper null and scalar presence for fields 2 through 7',
  production.includes('const handwritingSetter') &&
    production.includes('hasAlignTextToLines: table.hasField(3)') &&
    production.includes('hasDefaultFontFamily: hasDefaultFontFamily') &&
    production.includes('hasDefaultFontSize: table.hasField(5)') &&
    production.includes('hasLayoutMode: table.hasField(6)') &&
    production.includes('hasBlockWrapSupport: table.hasField(7)'));
check('Harmony validates original domains plus finite Float32 and one-page template PDF hardening',
  policy.includes('Number.isFinite(value) && value > 0') &&
    policy.includes('value.length <= ORIGINAL_DEFAULT_FONT_FAMILY_MAX_LENGTH') &&
    production.includes('SET_METADATA_TEMPLATE_PDF_PAGE_COUNT_UNSUPPORTED') &&
    production.includes('SET_METADATA_HANDWRITING_LANGUAGE_UNSUPPORTED') &&
    production.includes('SET_METADATA_LAYOUT_MODE_UNSUPPORTED') &&
    production.includes('SET_METADATA_BLOCK_WRAP_SUPPORT_UNSUPPORTED'));
const isoSection = policy.slice(policy.indexOf('const ORIGINAL_ISO_LANGUAGE_CODES'),
  policy.indexOf('export function isOriginalHandwritingLanguage'));
const isoCodes = [...isoSection.matchAll(/'([^']*)'/g)]
  .flatMap(match => match[1].split('|').filter(Boolean));
check('Harmony policy carries the 188 Java ISO codes including modern and legacy aliases',
  isoCodes.length === 188 && new Set(isoCodes).size === 188 &&
    ['he', 'iw', 'id', 'in', 'yi', 'ji'].every(code => isoCodes.includes(code)));
check('Harmony no longer atomically defers all six supported metadata fields',
  !production.includes('SET_METADATA_FIELDS_UNSUPPORTED') &&
    production.includes('hasMetadataField(payload)'));
check('Harmony reads and writes one independent SQL winner per metadata register',
  ['original_note_handwriting_language_winner',
    'original_note_align_text_to_lines_winner',
    'original_note_default_font_family_winner',
    'original_note_default_font_size_winner',
    'original_note_layout_mode_winner',
    'original_note_block_wrap_support_winner']
    .every(table => production.includes(table)));
const assetDecision = production.indexOf('const assetReason: string | null = applyBackground');
const lastIdentityConflict = production.lastIndexOf('_IDENTITY_CONFLICT');
const firstWinnerWrite = production.indexOf('if (applyTitle && payload.title !== null)');
check('all identity conflicts precede PDF asset mutation and every winner write',
  lastIdentityConflict >= 0 && assetDecision > lastIdentityConflict &&
    firstWinnerWrite > assetDecision &&
    production.includes('A stale background register is a complete no-op'));
check('a mixed metadata operation advances structure revision at most once',
  (production.match(/await this\.advanceStructureRevision\(/g) ?? []).length === 1 &&
    production.includes('applyTitle || applyBackground || applyHandwriting || applyAlign || applyFamily ||') &&
    production.includes('applySize || applyLayout || applyWrap'));
const readback = production.slice(
  production.indexOf('export async function readOriginalNoteMetadataState'));
check('Harmony reads one coherent snapshot and preserves handwriting absent versus explicit null',
  (readback.match(/querySql\(/g) ?? []).length === 1 &&
    readback.includes('FROM (SELECT ? AS note_id) target') &&
    readback.includes('hasHandwritingLanguage: handwritingPresent') &&
    readback.includes("throw new Error('stored original note metadata register is invalid')"));
check('blank-note bootstrap rejects residue in every new metadata winner table',
  ['handwriting_winners', 'align_winners', 'family_winners', 'size_winners',
    'layout_winners', 'wrap_winners'].every(name => bootstrap.includes(name)));
check('ArkTS FlatBuffer fixture covers all six fields explicit null and invalid values',
  fixture.includes('flatBufferSetMetadataRegisters(') &&
    fixture.includes('decodes and validates every additional SET_METADATA register') &&
    fixture.includes('SET_METADATA_HANDWRITING_LANGUAGE_UNSUPPORTED') &&
    fixture.includes('SET_METADATA_DEFAULT_FONT_FAMILY_UNSUPPORTED') &&
    fixture.includes('SET_METADATA_DEFAULT_FONT_SIZE_UNSUPPORTED') &&
    fixture.includes('SET_METADATA_LAYOUT_MODE_UNSUPPORTED') &&
    fixture.includes('SET_METADATA_BLOCK_WRAP_SUPPORT_UNSUPPORTED') &&
    fixture.includes('SET_METADATA_TEMPLATE_PDF_PAGE_COUNT_UNSUPPORTED'));
check('policy and database fixtures remain registered and lock v65 domains',
  policyFixture.includes("isOriginalHandwritingLanguage('iw_IL')") &&
    policyFixture.includes("isOriginalHandwritingLanguage('en-US')") &&
    databaseFixture.includes('expect(DB_VERSION).assertEqual(65)') &&
    databaseFixture.includes('MIGRATIONS[65]') &&
    fixtureList.includes("import originalNoteMetadataPolicyTest from './OriginalNoteMetadataPolicy.test';") &&
    fixtureList.includes('originalNoteMetadataPolicyTest();'));

if (failed > 0) {
  console.error(`D02_ORIGINAL_SET_METADATA_REGISTERS_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_ORIGINAL_SET_METADATA_REGISTERS_OK TOTAL=${total} FAILED=0`);
