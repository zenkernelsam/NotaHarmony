// Phase 594 — 文本编辑中块外点按 → 提交并停用（oke.a 等价）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   zl2.java case25 — TEXT 工具点按面（ha5 case0 → PointerInputEventHandler）：
//     qo5 qo5VarC = xtcVar.c(jE);           // 点按命中文本块
//     if (qo5VarC != null) qkeVar = new qke(qo5VarC);   // 命中 → 激活该块
//     else {
//       x09 x09VarC = xtcVar.a.c();
//       if (x09VarC != null && tl7.w(x09VarC, ei3.f(jE))) return null;
//         // 点按落在当前编辑块内 → 保持编辑，不分发
//       qkeVar = oke.a;                     // 块外 → 停用编辑器
//     }
//     uke.d(ukeVar, qkeVar, false, 2);
//   uke.java:270-282 — oke.a → asdVar CAS 清空活动文本编辑器（ake）。
//   e5j.java:291-310 — TEXT 工具的 ha5 pointer-input 处理器挂到画布。
// Harmony：textEditing 中 canvas pointer-down 先于工具分发判块内外——
//   块内 → 直接返回（TextArea 自理）；块外 → onTextCommit 提交并停用
//   （onTextCommit 尾部置 textEditing=false/editingTextBlock=null）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 编辑中块外点按 → 提交停用（先于一切工具分发） ---
const down = canvas.slice(canvas.indexOf('private onTouchDown('),
  canvas.indexOf('private onTouchDown(') + 2600);
check(down.includes('this.textEditing && this.editingTextBlock !== null'),
  'editing guard precedes tool dispatch');
check(down.includes('pointHitsTextBlock(canvasP, this.editingTextBlock)'),
  'inside-block tap keeps editing (tl7.w parity)');
check(down.includes('this.onTextCommit(this.editingDraftText)'),
  'outside-block tap commits the draft (oke.a → commit+deactivate)');
check(down.indexOf('this.textEditing && this.editingTextBlock !== null') <
  down.indexOf('this.viewModel.currentTool === ToolType.DEFAULT'),
  'editing check precedes the DEFAULT/double-tap branch');
check(down.indexOf('this.onTextCommit(this.editingDraftText)') <
  down.indexOf('this.viewModel.currentTool === ToolType.DEFAULT'),
  'outside-tap commit precedes tool dispatch (consumed tap)');

// --- onTextCommit 尾部即停用（oke.a 停用语义） ---
const commit = canvas.slice(canvas.indexOf('async onTextCommit('),
  canvas.indexOf('async onTextCommit(') + 5200);
check(commit.includes('this.textEditing = false;') &&
  commit.includes('this.editingTextBlock = null;'),
  'onTextCommit deactivates the editor');

console.log(`D02_ORIGINAL_TEXTEDIT_OUTSIDE_TAP_OK TOTAL=${n} FAILED=0`);
