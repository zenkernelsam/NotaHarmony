// D05 原版 LIBRARY_HOME 首页分区 fail-closed — Phase 706（ADR-0655）
// ac4.F0（LIBRARY_HOME，#47）远程旗标控制 Home 分区（CTA 卡 +
// favorite/recent 区 + study-up-next Learn 待办）；Harmony 经典库
// 等价旗标关闭态。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const ac4 = read(`${JADX}/sources/defpackage/ac4.java`);
const ajh = read(`${JADX}/sources/defpackage/ajh.java`);
const va7 = read(`${JADX}/sources/defpackage/va7.java`);
const ksh = read(`${JADX}/sources/defpackage/ksh.java`);
const ht8 = read(`${JADX}/sources/defpackage/ht8.java`);

const libraryPage = read('note/src/main/ets/ui/library/LibraryPage.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版旗标与门控 ---
check(ac4.includes('"LIBRARY_HOME", 47'),
  'LIBRARY_HOME flag declared (ac4.F0, #47)');
check(ajh.includes('lc4.a(ac4.F0)') && ajh.includes('feature_library__home'),
  'ajh inserts the Home nav entry only when the flag is on');
check(va7.includes('lc4.a(ac4.F0)'),
  'additional consumers gate on ac4.F0');

// --- Home 区组成 ---
check(ksh.includes('feature_library__home_record_lecture_title') &&
  ksh.includes('feature_library__home_take_notes'),
  'ksh.d dual CTA cards (Record a lecture / Take notes)');
check(ksh.includes('feature_library__home_favorite_notes_title') &&
  ksh.includes('feature_library__home_recent_notes_title') &&
  ksh.includes('feature_library__home_study_up_next_title'),
  'Home contains favorite/recent sections + study-up-next Learn widget');
check(strings.includes('home_take_notes_starter') &&
  strings.includes('home_subtitle') && strings.includes('home_lets_get_started'),
  'starter-count variant + subtitle + lets-get-started strings present');
check(ht8.includes('RECORD_LECTURE("record_lecture")'),
  'record_lecture analytics enum exists');

// --- Harmony 旗标关闭等价 ---
check(!libraryPage.includes('record_lecture') && !libraryPage.includes('study_up_next') &&
  !libraryPage.includes('home_take_notes'),
  'Harmony library ships no Home section (flag-off equivalent)');
check(libraryPage.includes('createAndRecord') && libraryPage.includes('createAndOpen'),
  'functional CTAs covered by the FAB create menu (record audio / new note)');

console.log(`D05_ORIGINAL_LIBRARY_HOME_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
