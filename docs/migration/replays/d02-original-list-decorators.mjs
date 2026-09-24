// Phase 683 — 原版文本格式工具条列表装饰项：fy2 BULLET(1)/NUMBER(2)/
//   CHECK_BOX(3) 段落样式切换（cve.o(fy2) 单选互斥）。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   fy2.java      枚举 NONE=0/BULLET=1/NUMBER=2/CHECK_BOX=3/
//                 BLOCK_QUOTE=4/CODE_BLOCK=5。
//   h32.java      case24/25/26：ui_text__bullet_list /
//                 ui_text__numbered_list / ui_text__checkbox_list 图标行。
//   cve.java      nue yse→o(fy2.BULLET)、xte→o(fy2.NUMBER)、
//                 zse→o(fy2.CHECK_BOX)；o(fy2) → m(m5a(fy2)) 段落样式 op。
//   strings.xml   ui_text__{bullet,numbered,checkbox}_list 三串。
// Harmony（TextBlockOverlay，Phase 681 同一 infra）：
//   底部行新增三枚段落装饰切换钮（光标段落粒度、再点取消、互斥单选），
//   toggleDecoratorStyle(1/2/3) 复用既有 draftStyles→paragraph runs
//   管线；isChecked 在样式切换间保留（原版 checkbox 勾选为独立字段）。
//   Canvas2DTextRenderer 对 decorator 1/2/3 的渲染（圆点/编号/checkbox
//   标记+命中）此前已就绪——本期只补 authoring 面。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const fy2 = fs.readFileSync(`${originalRoot}sources/defpackage/fy2.java`, 'utf8');
const h32 = fs.readFileSync(`${originalRoot}sources/defpackage/h32.java`, 'utf8');
const cve = fs.readFileSync(`${originalRoot}sources/defpackage/cve.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const overlay = fs.readFileSync('note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const renderer = fs.readFileSync('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8');
const en = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(fy2.includes('NONE((byte) 0)') && fy2.includes('BULLET((byte) 1)') &&
  fy2.includes('NUMBER((byte) 2)') && fy2.includes('CHECK_BOX((byte) 3)'),
  'fy2 枚举 NONE/BULLET/NUMBER/CHECK_BOX = 0..3');
check(h32.includes('ui_text__bullet_list') && h32.includes('ui_text__numbered_list') &&
  h32.includes('ui_text__checkbox_list'), 'h32 列表三图标行');
check(cve.includes('o(fy2.BULLET)') && cve.includes('o(fy2.NUMBER)') &&
  cve.includes('o(fy2.CHECK_BOX)'), 'cve.o(fy2) 列表三分发');
check(cve.includes('m(new m5a(fy2Var)'), 'cve.o → m5a 段落样式 op');
for (const key of ['bullet_list', 'numbered_list', 'checkbox_list']) {
  check(stringsXml.includes(`ui_text__${key}`), `original string ui_text__${key}`);
}

// --- Harmony 实现钉 ---
check(overlay.includes('this.toggleDecoratorStyle(1)') &&
  overlay.includes('this.toggleDecoratorStyle(2)') &&
  overlay.includes('this.toggleDecoratorStyle(3)'),
  '三枚列表切换钮 → toggleDecoratorStyle(1/2/3)');
check(overlay.includes('this.caretDecoratorStyle === 1') &&
  overlay.includes('this.caretDecoratorStyle === 2') &&
  overlay.includes('this.caretDecoratorStyle === 3'),
  '列表钮激活态按 caretDecoratorStyle');
for (const key of ['bullet_list', 'numbered_list', 'checkbox_list']) {
  check(overlay.includes(`$r('app.string.${key}')`), `overlay ${key} 按钮`);
  check(en.includes(`"name": "${key}"`), `en string ${key}`);
  check(zh.includes(`"name": "${key}"`), `zh string ${key}`);
}
// 互斥单选：同一 toggle 内 current!==decorator → set else 清除（复用 P681）。
check(overlay.includes('current.decoratorStyle !== decorator'),
  'toggleDecoratorStyle 互斥单选语义');
check(overlay.includes('next.isChecked = current.isChecked'),
  'isChecked 随样式切换保留');
// 渲染侧已就绪：decorator 1/2/3 + checkbox 标记列。
check(renderer.includes('decoratorStyle === 2') &&
  renderer.includes('decoratorStyle === 3') &&
  renderer.includes('drawCheckboxMarker'), 'renderer 列表/checkbox 渲染既有');

console.log(`D02_ORIGINAL_LIST_DECORATORS_OK TOTAL=${n} FAILED=0`);
