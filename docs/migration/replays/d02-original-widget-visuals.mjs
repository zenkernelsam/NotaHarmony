// Phase 726 — 非字符串资源尾部：app_widgets 调色板/dimen 视觉对齐 +
//   arrays/bools/integers/dimens/styles 平台/SDK 边界登记
// 原版证据：create_note_widget.xml / create_recording_widget.xml /
//   widget_notes*.xml / app_widgets__widget_*.xml drawable /
//   colors.xml app_widgets__* 12 色 / dimens.xml
//   app_widgets__widget_thumb_corner_radius=6dp。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');
const exists = (p) => fs.existsSync(R(p));

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

const newNote = read('note/src/main/ets/noteformability/pages/NewNoteCard.ets');
const newRec = read('note/src/main/ets/noteformability/pages/NewRecordingCard.ets');
const recent = read('note/src/main/ets/noteformability/pages/RecentNotesCard.ets');
const folder = read('note/src/main/ets/noteformability/pages/FolderNotesCard.ets');
const thumb = read('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets');

// === 建笔记磁贴（create_note_widget.xml）===
check('建笔记卡片 tile 底 #ecf2ff', newNote.includes("'#ecf2ff'"));
check('建笔记卡片 tile r20', newNote.includes('borderRadius(20)'));
check('建笔记标签 #171a20', newNote.includes("'#171a20'"));
check('建笔记主色钮 #4278ff r12', newNote.includes("'#4278ff'") && newNote.includes('borderRadius(12)'));
check('建笔记钮 40×40 挂 widget_add 图标', /widget_add[\s\S]*?width\(40\)/.test(newNote));
check('建笔记 CREATE_NOTE 路由保留', newNote.includes("launch_action: 'create_note'"));

// === 录音磁贴（create_recording_widget.xml）===
check('录音卡片 tile 底 #fff6ea', newRec.includes("'#fff6ea'"));
check('录音卡片 tile r20', newRec.includes('borderRadius(20)'));
check('录音主色钮 #ffa629 r12', newRec.includes("'#ffa629'") && newRec.includes('borderRadius(12)'));
check('录音钮挂 widget_record 图标', newRec.includes('widget_record'));
check('录音 create_recording_note 路由保留', newRec.includes("launch_action: 'create_recording_note'"));

// === 新增媒体 ===
check('widget_add.svg 存在且为 + 路径',
  exists('note/src/main/resources/base/media/widget_add.svg') &&
  read('note/src/main/resources/base/media/widget_add.svg').includes('M11,5h2v14h-2zM5,11h14v2h-14z'));
check('widget_record.svg 存在且为 mic 描边',
  exists('note/src/main/resources/base/media/widget_record.svg') &&
  read('note/src/main/resources/base/media/widget_record.svg').includes('M16,5.01C16,2.795'));

// === 列表卡片（widget_notes_row.xml / widget_bg / thumb_border）===
for (const [name, src] of [['recent', recent], ['folder', folder]]) {
  check(`${name} 行缩略图 r6 + 1px #e8ebf0 边框`,
    src.includes('borderRadius(6)') && src.includes("color: '#e8ebf0'"));
  check(`${name} 占位格 #f6f6f8 底 + #c8cfdb 图标`,
    src.includes("'#f6f6f8'") && src.includes(".fillColor('#c8cfdb')"));
  check(`${name} 行分隔线 1px #e8ebf0`,
    src.includes('strokeWidth(1)') && src.includes(".color('#e8ebf0')"));
  check(`${name} 末行后分隔线不省略（原版每行自带）`,
    !/index < this\.items\.length - 1[\s\S]{0,80}Divider/.test(src));
  check(`${name} 标题色 widget_text #0c0d11`, src.includes("'#0c0d11'"));
  check(`${name} 卡片底 widget_bg #ffffff r16`,
    src.includes("'#ffffff'") && src.includes('borderRadius(16)'));
}

// === 缩略图卡片（widget_note_thumbnail.xml）===
check('缩略图卡片占位 #f6f6f8 r16 + #c8cfdb',
  thumb.includes("'#f6f6f8'") && thumb.includes('borderRadius(16)') && thumb.includes(".fillColor('#c8cfdb')"));
check('缩略图 ImageFit.Fill（原版 fitXY 拉伸）', thumb.includes('ImageFit.Fill'));
check('缩略图卡片底 #ffffff', thumb.includes("'#ffffff'"));
check('缩略图 note_id 路由保留', thumb.includes('note_id: this.noteId'));

// === 边界登记（ADR-0674）===
const adr = read('docs/migration/adr/ADR-0674-original-nonstring-resources.md');
check('ADR-0674 存在', adr.length > 500);
check('ADR 覆盖 arrays.xml 边界', /arrays\.xml|chat_card_headers|spen_adaptive/.test(adr));
check('ADR 覆盖 qt_/quick_tool dimen 边界', /qt_|quick_tool/.test(adr));
check('ADR 覆盖 bools/integers 平台键', /bools\.xml|firebase|workmanager/i.test(adr));
check('ADR 覆盖 styles/ThemeSplash', /styles\.xml|ThemeSplash/.test(adr));
check('ADR 记录 widget 12 色与 6dp 角半径', /widget_note_tile_bg|#ecf2ff/.test(adr) && /6dp|corner_radius/.test(adr));

const evidence = read('docs/migration/evidence/original-nonstring-resources-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 400);
check('证据引用 widget 布局 XML', /create_note_widget|widget_notes_row/.test(evidence));
check('证据引用 dimen/颜色值', /widget_thumb_corner_radius|#4278ff/.test(evidence));

const report = read('docs/migration/reports/phase-726-original-nonstring-resources.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /widget_|arrays\.xml|qt_/.test(report));

console.log(`D02_ORIGINAL_WIDGET_VISUALS_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
