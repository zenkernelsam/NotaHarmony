// Phase 1409 — 库视图切换图标 + 笔记卡带标题 a11y（sof/l9b 等价，1.4.2 证据）。
//
// 原版证据（decompiled_1.4.2）：
//   sof case：视图切换钮——list 态显示 feature_library__grid_view（四枚描边
//     圆角方块 stroke），grid 态显示 ui_designsystem__list_bullet（三横线+
//     三圆点 fill）；cd = cd_switch_to_grid_view / cd_switch_to_list_view
//     （"Switch to grid/list view"）。
//   l9b（grid 卡 case0 + list 行 default 两分支同构）：多选勾选圈 f9n.b 的
//     a11y = cd_(de)select_note_titled（"Select note %1$s"/
//     "Deselect note %1$s"），str 为卡片物化标题。
//   mo2：设置侧笔记选择面同样使用 feature_settings__cd_(de)select_note_titled
//     ——同一措辞簇。
// Harmony 落点：ToolGlyphs.ets 新增 grid_view/list_bullet 原始矢量；
//   LibraryPage.ets 工具条 Button 文本符号 ⊞/☰ → ToolGlyph；SelectCircle
//   a11y select_note 静态串 → 带标题 cd（空标题回落 untitled_note 物化标题）。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const glyphs = readFileSync('note/src/main/ets/ui/components/ToolGlyphs.ets', 'utf8');
const baseStr = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStr = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 字符串资源：带标题选中 cd + switch-to cd（en + zh）──
for (const [key, en, zh] of [
  ['cd_select_note_titled', 'Select note %1$s', '选择笔记 %1$s'],
  ['cd_deselect_note_titled', 'Deselect note %1$s', '取消选择笔记 %1$s'],
  ['cd_switch_to_grid_view', 'Switch to grid view', '切换到网格视图'],
  ['cd_switch_to_list_view', 'Switch to list view', '切换到列表视图'],
]) {
  check(baseStr.includes(`"name": "${key}"`), `base 串 ${key}`);
  check(baseStr.includes(`"value": "${en}"`), `base 串 ${key} 文案`);
  check(zhStr.includes(`"name": "${key}"`), `zh 串 ${key}`);
  check(zhStr.includes(`"value": "${zh}"`), `zh 串 ${key} 文案`);
}

// ── ToolGlyphs：grid_view（o 层四方块描边）+ list_bullet（f 层横线圆点）──
check(/'grid_view': \{ f: ``/.test(glyphs), 'grid_view 仅描边层（feature_library__grid_view 等价）');
check(/'grid_view': \{ f: ``, o: `M3\.5,1\.5L8\.5,1\.5A2,2 0,0 1,10\.5 3\.5/.test(glyphs),
  'grid_view pathData 首方块');
check(/M15\.5,13\.5L20\.5,13\.5A2,2 0,0 1,22\.5 15\.5/.test(glyphs), 'grid_view pathData 末方块');
check(/'list_bullet': \{ f: `M6\.085,2\.364H20\.654/.test(glyphs),
  'list_bullet fill 层（ui_designsystem__list_bullet 等价）');
check(/list_bullet[\s\S]*?1\.485,15\.689Z/.test(glyphs), 'list_bullet 三圆点完整路径');

// ── 工具条视图切换钮：ToolGlyph 目标态图标 + switch-to cd ──
check(!/Button\(this\.listView \? '⊞' : '☰'\)/.test(lib), '文本符号 ⊞/☰ 已移除');
check(/glyph: this\.listView \? 'grid_view' : 'list_bullet'/.test(lib),
  'list 态 → grid_view 图标 / grid 态 → list_bullet（sof 目标态语义）');
check(/\.accessibilityText\(this\.listView \?\s*\$r\('app\.string\.cd_switch_to_grid_view'\) : \$r\('app\.string\.cd_switch_to_list_view'\)\)/.test(lib),
  '切换钮 cd = switch to grid/list view');

// ── SelectCircle：带标题 select/deselect cd（l9b 两分支同构）──
check(/cd_deselect_note_titled', this\.noteDisplayTitle\(note\)\)/.test(lib),
  '已选 → Deselect note <标题>');
check(/cd_select_note_titled', this\.noteDisplayTitle\(note\)\)/.test(lib),
  '未选 → Select note <标题>');
check(!/accessibilityText\(\$r\('app\.string\.select_note'\)\)/.test(lib),
  '静态 select_note 勾选圈 a11y 已移除');
check(/private noteDisplayTitle\(note: NoteMeta\): string \{[\s\S]*?untitled_note/.test(lib),
  'noteDisplayTitle 物化标题（空 → untitled_note，同卡片显示）');

// ── SelectCircle 复用覆盖 grid 卡 + list 行（l9b case0/default 等价）──
check(/if \(this\.isMultiSelecting\) \{\s*this\.SelectCircle\(note\)[\s\S]*?if \(this\.isMultiSelecting\) \{\s*this\.SelectCircle\(note\)/.test(lib),
  'grid 卡 + list 行共用 SelectCircle（双分支覆盖）');

console.log(`d02-original-library-view-a11y: ${n} checks OK`);
