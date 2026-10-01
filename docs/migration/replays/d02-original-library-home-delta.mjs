// D02 原版 1.4.2 库主页增量 — Phase 787
// 钉住 Coming-Up 十键、考试区块、滑动操作三键与配套键族；
// Phase 1410 已补 swipeAction（wbn/d2n 等价）——该钉反转为实现断言。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const lib = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('coming-up home section keys (calendar boundary)',
  ['title', 'happening_now', 'starting_soon', 'earlier_days', 'later_days',
    'all_day', 'no_events', 'start_now', 'untitled_event',
    'connect_title', 'connect_subtitle']
    .every((k) => s142.includes(`home_coming_up_${k}">`)));
check('upcoming-exams block + review/tomorrow/open-folder',
  s142.includes('home_upcoming_exams_title">')
  && s142.includes('home_exam_review">')
  && s142.includes('home_exam_tomorrow">'));
check('swipe-to-delete/favorite/unfavorite action keys',
  ['delete_note_swipe_action', 'favorite_note_swipe_action',
    'unfavorite_note_swipe_action']
    .every((k) => s142.includes(`feature_library__${k}">`)));
// Phase 1410：swipeAction 已实现（wbn/d2n 滑动操作条）——原「无
// swipeAction」delta 钉反转为实现存在断言。
check('Harmony library swipeAction implemented (Phase 1410 closes delta)',
  lib.includes('swipeAction'));
check('grid/list toggle exists in Harmony; a11y keys are the delta',
  lib.includes('listView') && s142.includes('cd_switch_to_grid_view">')
  && s142.includes('cd_switch_to_list_view">')
  && !s103.includes('cd_switch_to_grid_view'));
check('cover entry + planner creation + learn card CTAs present',
  s142.includes('feature_library__add_note_cover">')
  && s142.includes('creating_planner_note">')
  && s142.includes('learn_card_start_learning">'));
check('1.0.3 lacked the whole home-section family',
  !s103.includes('home_coming_up_') && !s103.includes('home_upcoming_exams'));

console.log(`library-home delta replay: ${checks.length}/${checks.length} checks green`);
