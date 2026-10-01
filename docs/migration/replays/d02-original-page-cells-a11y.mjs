// Phase 1408 — 页总览 cell 可访问性 + 书签角标交互 + 跳页清除钮
// （cbn/ie/bom/or 等价，1.4.2 证据）。
//
// 原版证据（decompiled_1.4.2）：
//   cbn.j 页 cell：书签角标经 fq9.d(function2,…) 无条件渲染——ie case2
//     按 dr2Var.c 切换 bookmark_tall_fill/outline 双图标，a11y =
//     cd_(un)bookmark_page_numbered（"Bookmark page %d"/"Remove bookmark
//     from page %d"，参数 i12 = 显示页码）；
//   wq2.invoke：角标点击普通态 → njg.b(pageKey) 写库切换书签，选择态 →
//     pr2.D(oag.x2(cbc(pageId))) 并入选中集；
//   cbn.j if(z2) 分支：选择态 checkbox f9n.b a11y =
//     cd_(de)select_page_numbered（"Select page %d"/"Deselect page %d"）；
//   bom 选择工具条 icon-button：cd_copy_pages "Copy selected pages" /
//     cd_duplicate_pages / cd_delete_pages；
//   or case18：跳页字段非空时尾部 xmark_circle_fill 钮，cd =
//     cd_clear_page_number "Clear page number"，点击清空 rgaVar 文本；
//   搜索钮激活态 cd = content_manager_close_search "Close search"。
// Harmony 落点：PageOverviewPanel.ets（cell 角标常渲染 + onToggleBookmark /
//   onPageBookmark 透传 + 编号 cd + chip cd + close-search cd）+
//   PageManagerBar.ets JumpToPageDialog（灰圆+× 组合清除钮）+
//   NotePage dispatchPageContextAction case 'bookmark' →
//   togglePageBookmarkAt（de2.m/ae2 v0 日记化同一写路径）。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const panel = readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8');
const notePage = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const managerBar = readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8');
const baseStr = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStr = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 字符串资源：编号 cd + 清除钮 + close-search + 批操作 cd ──
for (const [key, en, zh] of [
  ['cd_select_page_numbered', 'Select page %d', '选择第 %d 页'],
  ['cd_deselect_page_numbered', 'Deselect page %d', '取消选择第 %d 页'],
  ['cd_bookmark_page_numbered', 'Bookmark page %d', '为第 %d 页添加书签'],
  ['cd_unbookmark_page_numbered', 'Remove bookmark from page %d', '移除第 %d 页的书签'],
  ['cd_clear_page_number', 'Clear page number', '清除页码'],
  ['cd_pages_close_search', 'Close search', '关闭搜索'],
  ['cd_copy_pages', 'Copy selected pages', '拷贝所选页面'],
  ['cd_duplicate_pages', 'Duplicate selected pages', '复制所选页面'],
  ['cd_delete_pages', 'Delete selected pages', '删除所选页面'],
]) {
  check(baseStr.includes(`"name": "${key}"`), `base 串 ${key}`);
  check(baseStr.includes(`"value": "${en}"`), `base 串 ${key} 文案`);
  check(zhStr.includes(`"name": "${key}"`), `zh 串 ${key}`);
  check(zhStr.includes(`"value": "${zh}"`), `zh 串 ${key} 文案`);
}

// ── PageOverviewCell：书签角标无条件渲染 + fill/outline 切换 + 编号 cd ──
// 角标不再被 bookmarked===true 条件包裹（原版 fq9.d 无条件渲染）。
check(!/if \(this\.page\?\.bookmarked === true\) \{\s*\/\/ md\.java/.test(panel),
  '角标取消 bookmarked 条件渲染（原版无条件渲染）');
check(/glyph: this\.page\?\.bookmarked === true \?\s*'bookmark_tall_fill' : 'bookmark_tall_outline'/.test(panel),
  '角标 fill/outline 双图标按 dr2Var.c 切换');
check(/contentColor: this\.page\?\.bookmarked === true \?\s*this\.resolveTokens\(\)\.accent : this\.resolveTokens\(\)\.textSecondary/.test(panel),
  '角标 tint：bookmarked=accent / 未标=textSecondary');
check(/\.accessibilityText\(this\.page\?\.bookmarked === true \?\s*\$r\('app\.string\.cd_unbookmark_page_numbered', this\.pageIndex \+ 1\) :\s*\$r\('app\.string\.cd_bookmark_page_numbered', this\.pageIndex \+ 1\)\)/.test(panel),
  '角标编号 a11y（Bookmark/Remove bookmark page N）');

// 角标点击：选择态 → onToggleSelect（pr2.D 选择并集），普通态 →
// onToggleBookmark（njg.b 写库）。
check(/\.onClick\(\(\) => \{\s*if \(this\.selecting\) \{\s*this\.onToggleSelect\(this\.pageIndex\);\s*\} else \{\s*this\.onToggleBookmark\(this\.pageIndex\);/.test(panel),
  '角标点击：选择态选中 / 普通态切换书签');
check(/onToggleBookmark: \(pageIndex: number\)[\s\S]*?= \(_pageIndex: number\): void/.test(panel),
  'cell onToggleBookmark prop 声明');

// checkbox 编号 a11y（f9n.b 等价）。
check(/\.accessibilityText\(this\.checked \?\s*\$r\('app\.string\.cd_deselect_page_numbered', this\.pageIndex \+ 1\) :\s*\$r\('app\.string\.cd_select_page_numbered', this\.pageIndex \+ 1\)\)/.test(panel),
  '选择框编号 a11y（Select/Deselect page N）');

// ── PageOverviewPanel：onPageBookmark prop + cell 透传 ──
check(/onPageBookmark: \(pageIndex: number\)[\s\S]*?= \(_pageIndex: number\): void/.test(panel),
  '面板 onPageBookmark prop 声明');
check(/onToggleBookmark: \(pageIndex: number\): void => \{\s*\/\/ wq2 普通态分支[\s\S]*?this\.onPageBookmark\(pageIndex\);/.test(panel),
  'cell 角标 → 面板 onPageBookmark 透传');

// ── 选择工具条 chip a11y（bom icon-button cd 等价）──
// accessibilityText 仅接受 string|Resource 两重重载 → cd 参数类型为
// Resource，无 cd 分支不挂 accessibilityText（可见文本即 a11y）。
check(/cd\?: Resource\)/.test(panel) && /if \(cd === undefined\)[\s\S]*?\} else \{[\s\S]*?\.accessibilityText\(cd\)/.test(panel),
  'SelectionActionChip 可选 cd 参数（Resource，分支挂载）');
check(/\$r\('app\.string\.copy_page'\)[\s\S]*?\$r\('app\.string\.cd_copy_pages'\)/.test(panel),
  'copy chip → cd_copy_pages');
check(/\$r\('app\.string\.duplicate_page'\)[\s\S]*?\$r\('app\.string\.cd_duplicate_pages'\)/.test(panel),
  'duplicate chip → cd_duplicate_pages');
check(/\$r\('app\.string\.delete_page'\)[\s\S]*?\$r\('app\.string\.cd_delete_pages'\)/.test(panel),
  'delete chip → cd_delete_pages');

// ── 搜索钮激活态 cd = close search（content_manager_close_search）──
check(/\.accessibilityText\(this\.searchActive \?\s*\$r\('app\.string\.cd_pages_close_search'\)\s*:\s*\$r\('app\.string\.cd_pages_panel_search'\)\)/.test(panel),
  '搜索钮激活态 cd → Close search');

// ── NotePage：onPageBookmark 接线 + dispatchPageContextAction 'bookmark' ──
check(/onPageBookmark: \(pageIndex: number\): void => \{\s*this\.dispatchPageContextAction\(pageIndex, 'bookmark'\);/.test(notePage),
  'onPageBookmark → dispatchPageContextAction bookmark');
check(/case 'bookmark':\s*\/\/ wq2[\s\S]*?await this\.togglePageBookmarkAt\(pageIndex\)/.test(notePage),
  'dispatch case bookmark → togglePageBookmarkAt（de2.m/ae2 v0 同路径）');

// ── JumpToPageDialog：or case18 清除钮 ──
check(/Stack\(\{ alignContent: Alignment\.End \}\)[\s\S]*?TextInput\(\{ text: this\.inputText/.test(managerBar),
  '跳页字段 Stack End 对齐包裹');
check(/if \(this\.inputText\.length > 0\)[\s\S]*?cd_clear_page_number[\s\S]*?this\.inputText = ''/.test(managerBar),
  '字段非空 → 清除钮渲染（cd_clear_page_number）且点击清空');
check(/glyph: 'close_med_regular'[\s\S]*?contentColor: this\.resolveTokens\(\)\.control/.test(managerBar),
  '清除钮 = 灰圆底 + × 取字段底色（xmark_circle_fill 镂空等价）');
check(managerBar.includes(".padding({ right: 34 })"),
  '字段右侧内边距为清除钮留位');

console.log(`d02-original-page-cells-a11y: ${n} checks OK`);
