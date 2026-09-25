import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const repo = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const base = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
const adr = read('docs/migration/adr/ADR-0694-original-library-home-port.md');

// 原版证据（ajh:335 + vdh.b + ksh.a）：LIBRARY_HOME 默认 true →
// 侧栏首位 Home 导航项；选中时内容宿主渲染 ksh Home 组合而非网格。

// 伪分区值
assert.match(repo, /HOME = 4/);
// VM：homeFavorites/homeRecents 投影 + HOME 查询映射
assert.match(vm, /homeFavorites: NoteMeta\[\] = \[\]/);
assert.match(vm, /homeRecents: NoteMeta\[\] = \[\]/);
assert.match(vm,
  /section === LibrarySection\.HOME && folderId === null[\s\S]*getFavoriteNotes\(\)[\s\S]*getRecentNotes\(\)/);
assert.match(vm, /section === LibrarySection\.HOME[\s\S]*getAllNotes\(\)/);
assert.match(vm, /section !== LibrarySection\.HOME/);
// 导航项：两处 SectionNavRow 站点 Home 在 All Notes 前
assert.match(page,
  /SectionNavRow\(\$r\('app\.string\.home'\), LibrarySection\.HOME, 16\)[\s\S]*SectionNavRow\(\$r\('app\.string\.all_notes'\)/);
assert.match(page,
  /SectionNavRow\(\$r\('app\.string\.home'\), LibrarySection\.HOME, 8\)[\s\S]*SectionNavRow\(\$r\('app\.string\.all_notes'\)/);
// 内容分发：HOME + 无文件夹 + 搜索空 → HomeContent
assert.match(page,
  /currentSection === LibrarySection\.HOME[\s\S]*searchText\.trim\(\)\.length === 0[\s\S]*HomeContent\(\)/);
// Home 组合：图标 + 双 CTA + 条件分区
assert.match(page, /app\.media\.startIcon/);
assert.match(page, /createAndLaunch\(true\)/);
assert.match(page, /createAndLaunch\(false\)/);
assert.match(page, /viewModel\.homeFavorites\.length > 0/);
assert.match(page, /viewModel\.homeRecents\.length > 0/);
assert.match(page, /\.width\(220\)/);
// 字符串：9 键双语（值与原版 strings.xml 一致）
for (const key of ['home', 'home_lets_get_started', 'home_subtitle',
  'home_record_lecture_title', 'home_record_lecture_subtitle',
  'home_take_notes', 'home_take_notes_subtitle',
  'home_favorite_notes_title', 'home_recent_notes_title']) {
  assert.match(base, new RegExp(`"name": "${key}"`));
  assert.match(zh, new RegExp(`"name": "${key}"`));
}
assert.match(base, /"home",\s*"value": "Home"/);
assert.match(base, /"home_take_notes",\s*"value": "Take notes"/);
// fail-closed：starter/study_up_next 键不落资源
assert.doesNotMatch(base, /home_take_notes_starter|home_study_up_next/);
// ADR 登记
assert.match(adr, /home_study_up_next/);
assert.match(adr, /take_notes_starter/);

console.log('D02_ORIGINAL_LIBRARY_HOME_OK ' +
  'enum=1|vm-pins=5|nav=2|dispatch=1|content-pins=6|strings=20|failclosed=2');
