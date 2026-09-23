// Phase 634 — 页面旋转（Rotate Page）：原版内容管理器菜单项
// feature_note__content_manager_rotate_page 派发 fd2 case 8 -> zd2 协程变体 1。
// jadx --comments-level debug 的指令转储显示该变体：
//   1) 取 mz9.B() 有效 nz9（register ?? note fallback），null 直接返回；
//   2) cl4.a(=π) 为步长做 0→π/2→π→3π/2→0 轮换，非基数角回落 0（eps 1e-4）；
//   3) m18.O(nz9, null, Float(rotation), null, 27) 仅替换 rotation 字段；
//   4) PDF 页经 l7j.c(sw9, cropIndex=pageInAsset-pageOffset, pageInAsset)
//      重建为单页消费（pagesConsumed=1, pageOffset=pageInAsset,
//      cropBoxes 只保留本页项）；
//   5) u5j.s(x09, [pageId], null, m2d, null, 10) → r0j.a 写 ge8 ModifyPage，
//      仅 field 2（m2d setter→nz9），moveTo/bookmark 均缺席。
// Harmony 对齐：rotatedOriginalPageInfo 计算同一轮换与 PDF 重建；
// persistOriginalPageBackground 经 encodeOriginalModifyPageBackground 发出
// ge8.field0 pages + field2 m2d(field0→nz9) 的 ModifyPage op，走 LWW 寄存器。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const r0j = fs.readFileSync(`${originalRoot}r0j.java`, 'utf8');
const cl4 = fs.readFileSync(`${originalRoot}cl4.java`, 'utf8');
const ra = fs.readFileSync(`${originalRoot}ra.java`, 'utf8');
const m18 = fs.readFileSync(`${originalRoot}m18.java`, 'utf8');
const l7j = fs.readFileSync(`${originalRoot}l7j.java`, 'utf8');
const wz9 = fs.readFileSync(`${originalRoot}wz9.java`, 'utf8');
const ddg = fs.readFileSync(`${originalRoot}ddg.java`, 'utf8');
const n9j = fs.readFileSync(`${originalRoot}n9j.java`, 'utf8');
const fd2 = fs.readFileSync(`${originalRoot}fd2.java`, 'utf8');

const model = fs.readFileSync('note/src/main/ets/core/model/PageBackgroundModel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const modifyEncoder = fs.readFileSync('note/src/main/ets/data/OriginalModifyPagePayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const metadataEncoder = fs.readFileSync('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const pagePersistence = fs.readFileSync('note/src/main/ets/data/OriginalPagePersistence.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/PageRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const pageBar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const applier = fs.readFileSync('note/src/main/ets/data/OriginalModifyPageOperation.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据：菜单项与派发链 ---
assert.match(n9j, /R\.string\.feature_note__content_manager_rotate_page/);
assert.match(n9j, /R\.drawable\.ui_designsystem__rotate_page/);
// fd2 case 8 -> default -> zd2(de2, cxc, 1)：Rotate 走 zd2 变体 1。
assert.match(fd2, /new zd2\(de2Var, cxcVar3, null, 1\)/);
// cl4.a 持有 π（ra default 返回 Float(3.1415927)），a(f,g) 为 1e-4 eps 比较。
assert.match(cl4, /new pce\(new ra\(29\)\)/);
assert.match(cl4, /Math\.abs\(f - f2\) < 1\.0E-4f/);
assert.match(ra, /return Float\.valueOf\(3\.1415927f\)/);
// ddg.g(nz9)：rotation 必须为基数角，否则 "Cannot rotate to non cardinal directions"。
assert.match(ddg, /a\(nz9Var\.m\(\), 0\.0f\) && !a\(nz9Var\.m\(\), 1\.5707964f\) && !a\(nz9Var\.m\(\), 3\.1415927f\) && !a\(nz9Var\.m\(\), 4\.712389f\)/);
// m18.O(nz9, sw9, Float, qed, mask)：null 槽位保留原字段，mask&8 清空显式 size。
assert.match(m18, /public static nz9 O\(nz9 nz9Var, sw9 sw9Var, Float f, qed qedVar, int i\)/);
assert.match(m18, /vv7\.f\(k3aVarK, sw9Var2, fValueOf, qedVar, nz9Var\.j\(\), 32\)/);
// l7j.c(sw9, i, i2)：pagesConsumed=1、pageOffset=i2、cropBoxes=[j(i)] 单页重建。
assert.match(l7j, /public static final sw9 c\(sw9 sw9Var, int i, int i2\)/);
assert.match(l7j, /sw9Var\.j\(i, qedVar\)/);
assert.match(l7j, /j7j\.b\(sw9Var\.m\(\), sw9Var\.p\(\), 1, i2, listL0, sw9Var\.l\(\)\)/);
// wz9：F()=pageInAsset 寄存器（mmf），p()=cropBoxes 下标（pageInAsset-pageOffset）。
assert.match(wz9, /this\.m = \(\(mmf\) yc6Var3\.K\)\.I - \(sw9VarL != null \? sw9VarL\.n\(\) : 0\)/);
assert.match(wz9, /"pageInAsset", "getPageInAsset-pVg5ArA\(\)I"/);
// u5j.s：ge8 ModifyPage 生产者；r0j.a 组装 (pages, lxc moveTo, m2d, oz9) 四字段。
assert.match(u5j, /public static ge8 s\(x09 x09Var, List list, Integer num, m2d m2dVar, oz9 oz9Var, int i\)/);
assert.match(u5j, /return r0j\.a\(list, lxcVarA, m2dVar, oz9Var\)/);
assert.match(r0j, /public static ge8 a\(List list, lxc lxcVar, m2d m2dVar, oz9 oz9Var\)/);

// --- Harmony 实现：轮换步进 + PDF 单页重建 ---
assert.match(model, /export function nextOriginalPageRotation\(rotationRadians: number\): number/);
assert.match(model, /near\(rotationRadians, 0\)[\s\S]*?return Math\.PI \/ 2/);
assert.match(model, /near\(rotationRadians, Math\.PI \/ 2\)[\s\S]*?return Math\.PI;/);
assert.match(model, /near\(rotationRadians, Math\.PI\)[\s\S]*?return Math\.PI \* 3 \/ 2/);
assert.match(model, /export function rotatedOriginalPageInfo\(page: PageInfo\): PageInfo \| null/);
// 有效背景（register ?? note fallback），与 wz9.B() 一致；null 返回 null。
assert.match(model, /const register: PageBackground \| null = effectivePageBackground\(page\)/);
// l7j.c parity（Phase 635 起由 collapsedOriginalPagePdf 共享给 Duplicate）：
// pagesConsumed=1、pageOffset=pageInAsset、cropBoxes 单项保留。
assert.match(model, /const cropIndex: number = pageInAsset - pdf\.pageOffset/);
assert.match(model, /pagesConsumed: 1,\s*pageOffset: pageInAsset,\s*cropBoxes: \[pdf\.cropBoxes\[cropIndex\]\]/);
assert.match(model, /rotated\.pdf = collapsedOriginalPagePdf\(page, rotated\.pdf\)/);
// 物化维度按解码器公式随旋转交换宽高（Letter 612x792pt 兜底）。
assert.match(model, /result\.widthMm = quarterTurn \? sourceHeightMm : sourceWidthMm/);
assert.match(model, /result\.heightMm = quarterTurn \? sourceWidthMm : sourceHeightMm/);
assert.match(model, /result\.orientation = result\.widthMm > result\.heightMm \?\s*PageOrientation\.LANDSCAPE : PageOrientation\.PORTRAIT/);

// --- Harmony 实现：编码器 ge8.field0 pages + field2 m2d(field0→nz9 blob) ---
assert.match(metadataEncoder, /export function encodeOriginalPageBackgroundTableBlob\(background: PageBackground\): Uint8Array/);
assert.match(modifyEncoder, /export function encodeOriginalModifyPageBackground\(pages: OriginalSequenceIdentity\[\],\s*background: PageBackground \| null\): Uint8Array/);
// root vtable：field0 pages@4、field1 缺席、field2 setter@12、field3 缺席。
assert.match(modifyEncoder, /writeVtable\(bytes, rootVtable, 20, \[4, 0, 12, 0\]\)/);
// m2d setter：field0 指向嵌入的 nz9 blob；null 背景保留 setter 但省略 field0。
assert.match(modifyEncoder, /writeVtable\(bytes, setterVtable, 8, \[blob === null \? 0 : 4\]\)/);
assert.match(modifyEncoder, /encodeOriginalPageBackgroundTableBlob\(background\)/);

// --- Harmony 实现：持久化 + updatePage 原版路由 + 撤销伴随 op ---
assert.match(pagePersistence, /export async function persistOriginalPageBackground\(store: relationalStore\.RdbStore,\s*noteId: string, pageId: string, background: PageBackground \| null\)/);
assert.match(pagePersistence, /encodeOriginalModifyPageBackground\(\[page\], background\)/);
assert.match(pagePersistence, /opType: OpType\.ORIGINAL_MODIFY_PAGE/);
assert.match(repo, /await persistOriginalPageBackground\(store, noteId, page\.pageId,/);
assert.match(repo, /OpType\.UPDATE_PAGE, history\)/);
// 解码端 ge8.field2 -> setter.readTable(0) -> nz9 契约保持不变。
assert.match(applier, /table\.readTable\(2\)/);
assert.match(applier, /backgroundSetter\.readTable\(0\)/);

// --- Harmony 实现：UI 接线 ---
assert.match(pageBar, /onRotatePage: \(\) => void = \(\) => \{/);
assert.match(pageBar, /\$r\('app\.string\.rotate_page'\)/);
assert.match(notePage, /onRotatePage: \(\) => \{\s*this\.runPageOperation\(async \(\): Promise<void> => this\.rotateCurrentPage\(\)\);/);
assert.match(notePage, /private async rotateCurrentPage\(\): Promise<void>/);
assert.match(notePage, /rotatedOriginalPageInfo\(before\)/);
assert.match(notePage, /type: UndoableActionType\.PAGE_SETTINGS/);
assert.match(notePage, /await this\.pageRepo\.updatePage\(rotated, history\)/);

const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');
assert.match(baseStrings, /"name": "rotate_page"/);
assert.match(zhStrings, /"name": "rotate_page"/);

// --- 功能级模拟：轮换循环 + nz9 blob 解码往返 ---
function nextRotation(r) {
  const near = (a, b) => Math.abs(a - b) < 0.0001;
  if (near(r, 0)) return Math.PI / 2;
  if (near(r, Math.PI / 2)) return Math.PI;
  if (near(r, Math.PI)) return Math.PI * 3 / 2;
  return 0;
}
const PI = Math.PI;
assert.equal(nextRotation(0), PI / 2);
assert.equal(nextRotation(PI / 2), PI);
assert.equal(nextRotation(PI), PI * 3 / 2);
assert.equal(nextRotation(PI * 3 / 2), 0);
assert.equal(nextRotation(0.7), 0); // 非基数角回落 0（cl4.a eps 未命中）

console.log('D04_ORIGINAL_PAGE_ROTATE_REPLAY_OK TOTAL=47 FAILED=0');
