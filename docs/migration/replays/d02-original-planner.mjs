// Phase 1406 — 原版 1.4.2 计划本（x1d/e2d/y1d/a2d/b13/hel/l19/x2n.c 等价）。
// 原版证据（decompiled_1.4.2）：
//   x1d：Planner 枚举（仅 ACADEMIC_2026_2027；a()=封面列表，b()=首封面）。
//   e2d：PlannerWeekStart{MONDAY(0),SUNDAY(1)}；F=文件名段
//     monday_start/sunday_start；G=week_start_* 名字 res。
//   y1d：PlannerCover×4（PIN/LATTICE/SCALLOP/ARCHES；G=ui_planners__cover_*_N
//     .webp drawable，H=cover_* 名字 res）。
//   a2d.a(weekStart,cover,title)：planners/academic_planner_2026_2027-
//     <e2d.F>.pdf → b.d("<title>.pdf", w95(其它封面序号集合) 谓词,
//     资产 loader) 导入管线 → tf7 成功结果。
//   d2d(y1d) 默认构造 = 首个封面 + MONDAY。
//   hel.c(x1d)：getting-started 面 "Planners" 分区 cell（首封面 + 标题）。
//   hel.b(e2d,y1d,onWeekStart,onCover)：qmm 周起点分段 + ne9.d 封面格。
//   x2n.c/l19：d2d!=null → 配置屏（back + 标题 + hel.b + wuh.CREATE CTA）。
//   fel：模态 "Creating your planner note"；kan：planner_failed snackbar。
// Harmony 落点：rawfile/planners/（2 PDF + 4 webp）+ PlannerCatalog
//   （x1d/e2d/y1d 目录）+ HomeContent "Planners" 分区 + bindSheet 配置屏
//   （分段行 + 封面格 + Create）→ importBundledPdfFromBytes 物化笔记 →
//   cover_preset="planner_<index>"（NoteCoverCatalog image 分支渲染缩略图）。
import { readFileSync, readdirSync, statSync } from 'node:fs';
import assert from 'node:assert';

const catalog = readFileSync('note/src/main/ets/core/model/PlannerCatalog.ets', 'utf8');
const coverCatalog = readFileSync('note/src/main/ets/core/model/NoteCoverCatalog.ets', 'utf8');
const library = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const importer = readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');
const plannerDir = 'note/src/main/resources/rawfile/planners';

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 资产：planners/ 2 PDF + 4 webp 封面（非零大小，键名齐全）──
const files = readdirSync(plannerDir);
check(files.includes('academic_planner_2026_2027-monday_start.pdf'),
  'monday_start.pdf 落库');
check(files.includes('academic_planner_2026_2027-sunday_start.pdf'),
  'sunday_start.pdf 落库');
for (let i = 0; i < 4; i++) {
  check(files.includes(`cover_${i}.webp`), `cover_${i}.webp 落库`);
  check(statSync(`${plannerDir}/cover_${i}.webp`).size > 0,
    `cover_${i}.webp 非空`);
}
check(statSync(`${plannerDir}/academic_planner_2026_2027-monday_start.pdf`).size > 0,
  'monday pdf 非空');
check(statSync(`${plannerDir}/academic_planner_2026_2027-sunday_start.pdf`).size > 0,
  'sunday pdf 非空');

// ── PlannerCatalog：x1d/e2d/y1d 目录等价 ──
check(catalog.includes("key: 'monday'") && catalog.includes("fileSegment: 'monday_start'"),
  'e2d MONDAY 段');
check(catalog.includes("key: 'sunday'") && catalog.includes("fileSegment: 'sunday_start'"),
  'e2d SUNDAY 段');
check(catalog.indexOf("key: 'monday'") < catalog.indexOf("key: 'sunday'"),
  'e2d 枚举序 MONDAY→SUNDAY');
check(catalog.includes("PLANNER_DEFAULT_WEEK_START") &&
  catalog.includes('PLANNER_WEEK_STARTS[0]'),
  'd2d 默认 MONDAY（首个 weekStart）');
const COVER_KEYS = ['planner_0', 'planner_1', 'planner_2', 'planner_3'];
const COVER_NAMES = ['planner_cover_pinstripe', 'planner_cover_lattice',
  'planner_cover_scallop', 'planner_cover_arches'];
for (let i = 0; i < 4; i++) {
  check(catalog.includes(`presetKey: '${COVER_KEYS[i]}'`),
    `y1d 封面键 ${COVER_KEYS[i]}`);
  check(catalog.includes(COVER_NAMES[i]), `y1d 封面名 ${COVER_NAMES[i]}`);
  check(catalog.includes(`planners/cover_${i}.webp`), `封面 ${i} 路径`);
}
const coverOrder = COVER_KEYS.map((k) => catalog.indexOf(`'${k}'`));
check(coverOrder.every((v, i) => i === 0 || v > coverOrder[i - 1]),
  'y1d 枚举序 PIN→LAT→SCA→ARCH');
check(catalog.includes("id: 'academic_planner_2026_2027'"), 'x1d 计划本 id');
check(catalog.includes('plannerPdfPath') &&
  catalog.includes('planners/${entry.id}-${weekStart.fileSegment}.pdf'),
  'a2d 资产路径拼接');
check(catalog.includes('plannerDefaultCover'), 'x1d.b() 首封面等价');

// ── NoteCoverCatalog：planner_* 封面图像源 ──
check(coverCatalog.includes('PLANNER_COVER_PRESETS'), '计划本封面注册表');
for (let i = 0; i < 4; i++) {
  check(coverCatalog.includes(`key: 'planner_${i}'`), `注册表 planner_${i}`);
}
check(coverCatalog.includes("kind: 'image'"), 'image 源判别');
check(coverCatalog.includes("kind: 'pdf'"), 'iw2 预设仍为 pdf');
check(coverCatalog.includes('findAnyNoteCover'), '合并查找入口');
check(coverCatalog.includes('findNoteCoverPreset'), '预设查找保留');
check(coverCatalog.includes('loadImageCoverThumb') &&
  coverCatalog.includes('createImageSource'), 'webp 图像解码分支');
check(coverCatalog.includes('getRawFileContent'), 'rawfile 读取');
// 预设选择器仍只列 iw2 十款（原版 ebn 选择器不含计划本封面）
const sheet = readFileSync('note/src/main/ets/ui/editor/NoteCoverSheet.ets', 'utf8');
check(sheet.includes('NOTE_COVER_PRESETS') &&
  !sheet.includes('PLANNER_COVER_PRESETS'), '选择器只列 iw2 预设');

// ── HomeContent：Planners 分区（a1n.d f8m.d + hel.c）──
check(library.includes('HomePlannerSection'), 'Planners 分区渲染器');
check(library.includes("planners_title"), '分区标题');
check(library.includes("$rawfile('planners/cover_0.webp')"),
  'cell 预览 = 首个封面（x1d.b().G 等价）');
check(library.includes('ACADEMIC_PLANNER.titleRes'), 'cell 标题');
check(library.includes('plannerSheetOpen = true'), '点击开配置 sheet');
check(library.includes("plannerWeekStartKey = 'monday'"),
  '默认 weekStart=MONDAY（d2d 默认构造）');
check(library.includes('plannerCoverIndex = 0'),
  '默认封面=首个（x1d.b()）');
// 分区次序：Recents 之后（a1n.d 次序）
const recentsIdx = library.indexOf('home_recent_notes_title');
const plannerIdx = library.indexOf('HomePlannerSection()');
check(recentsIdx > 0 && plannerIdx > recentsIdx, '分区次序 Recents→Planners');

// ── 配置 sheet：x2n.c + hel.b ──
check(library.includes('PlannerConfigSheet') &&
  library.includes('bindSheet(this.plannerSheetOpen'), '配置 bindSheet');
check(library.includes('chevron_left') && library.includes("'back'") ||
  library.includes("app.string.back"), '返回钮');
check(library.includes('PLANNER_WEEK_STARTS'), 'qmm 周起点分段');
check(library.includes('plannerWeekStartKey === start.key'), '分段选中态');
check(library.includes('PLANNER_COVERS'), 'ne9.d 封面格');
check(library.includes('plannerCoverIndex === cover.index'), '封面选中态');
check(library.includes('GridItem') && library.includes('columnsTemplate'),
  '封面栅格');
check(library.includes('planner_create'), 'wuh.CREATE CTA');

// ── 创建管线：a2d → 导入 → 封面 → 打开 ──
check(library.includes('createPlannerNote'), '创建入口');
check(library.includes('plannerCreating'), 'fel 模态进度态');
check(library.includes('creating_planner_note'), 'fel 进度文案');
check(library.includes('getRawFileContent(plannerPdfPath(ACADEMIC_PLANNER'),
  'a2d 资产读取');
check(library.includes('importBundledPdfFromBytes'), 'PDF 导入管线');
check(library.includes('${title}.pdf'), 'a2d strN=<title>.pdf 文件名');
check(library.includes('setNoteCoverPreset(report.noteId, cover.presetKey)') ||
  library.includes('setNoteCoverPreset(report.noteId'),
  '封面键写入 cover_preset');
check(library.includes('planner_failed'), 'kan 失败 snackbar');
check(library.includes('router.pushUrl') &&
  library.includes('noteId: report.noteId'), '创建后打开笔记');
check(importer.includes('importBundledPdfFromBytes') &&
  importer.includes('importPdfFromBytes(data, fileName'), '导入委派');

// ── 字符串 ──
check(en.includes('"planners_title"') && en.includes('"Planners"'),
  'en 分区标题');
check(en.includes('"planner_academic_2026_2027"') &&
  en.includes('"2026–2027 Academic Planner"'), 'en 计划本名');
check(en.includes('"planner_week_start_monday"') &&
  en.includes('"Monday start"'), 'en 周一起点');
check(en.includes('"planner_week_start_sunday"') &&
  en.includes('"Sunday start"'), 'en 周日起点');
check(en.includes('"planner_cover_pinstripe"') && en.includes('"Pinstripe"') &&
  en.includes('"planner_cover_lattice"') && en.includes('"Lattice"') &&
  en.includes('"planner_cover_scallop"') && en.includes('"Scallop"') &&
  en.includes('"planner_cover_arches"') && en.includes('"Arches"'),
  'en 封面名');
check(en.includes('"planner_create"') && en.includes('"Create"'),
  'en Create CTA');
check(en.includes('"creating_planner_note"') &&
  en.includes('"Creating your planner note"'), 'en 进度文案');
check(en.includes('"planner_failed"') &&
  en.includes("Couldn't create note from planner"), 'en 失败文案');
check(zh.includes('"planners_title"') && zh.includes('"计划本"'), 'zh 分区标题');
check(zh.includes('"planner_academic_2026_2027"') &&
  zh.includes('2026–2027'), 'zh 计划本名');
check(zh.includes('"planner_week_start_monday"') &&
  zh.includes('"周一开始"'), 'zh 周一起点');
check(zh.includes('"planner_week_start_sunday"') &&
  zh.includes('"周日开始"'), 'zh 周日起点');
check(zh.includes('"planner_cover_pinstripe"') &&
  zh.includes('"planner_cover_arches"'), 'zh 封面名');
check(zh.includes('"planner_create"') && zh.includes('"创建"'), 'zh Create');
check(zh.includes('"creating_planner_note"') && zh.includes('计划本'),
  'zh 进度文案');
check(zh.includes('"planner_failed"') && zh.includes('计划本'), 'zh 失败文案');

console.log(`d02-original-planner: ${n} checks passed`);
