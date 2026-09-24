// Phase 602 — 选区手势挂起文本编辑器（pke.a / NoneActive）：内容提交但会话
// 保留，再激活同块恢复光标。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   pke.java — NoneActive，rke 事件的"挂起"变体（非销毁）。
//   uke.java d(uke,rke,z,i) — pke.a 分支：asdVar CAS 置 null（编辑器隐藏），
//     ake 会话对象保留在 uke.p 映射；尾部（z3=false 路径）仍启动
//     mub(uke,xhe,x09,qo5,null,8) 协程把草稿写回文档 → 内容提交+会话保留。
//   uke.d 中 mej.g(mke, TRUE, !z3, z3, z3?false:z2, 20) — 隐藏 IME。
//   ct0.java:48 — ClearSelection 手势分发 → xtcVar.d(pke.a,false,true)。
//   uw2.java:114 — TapToSelect 手势分发 → xtcVar.d(pke.a,false,true)。
//   uke.java:211 — 外部文本块变更含活动块 → d(uke,pke.a,false,6)。
//   zl2.java:203 — TEXT 工具面块外点按 → oke.a（提交并销毁，对照路径）。
//   uke.java b()/d() — qke 激活时 p.get(id) 命中挂起会话 → 恢复其状态。
// Harmony：非 DEFAULT 工具块外点按 → suspendTextEditing（onTextCommit 提交
//   + suspendedCaretByBlock 记录块光标）；beginTextEditingAt 命中块时
//   textEditingRestoreCaret 取回 → TextBlockOverlay.caretPosition 恢复。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVERLAY = 'note/src/main/ets/ui/components/TextBlockOverlay.ets';
const canvas = readFileSync(CANVAS, 'utf8');
const overlay = readFileSync(OVERLAY, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 分发分流：DEFAULT → oke 销毁；其余工具 → pke 挂起 ---
const down = canvas.slice(canvas.indexOf('private onTouchDown('),
  canvas.indexOf('private onTouchDown(') + 2600);
check(down.includes('this.viewModel.currentTool === ToolType.DEFAULT') &&
  down.includes('this.suspendTextEditing()'),
  'outside-tap deactivation splits oke (DEFAULT) vs pke (other tools)');

// --- suspendTextEditing：先提交（mub 等价），完成后写入挂起光标 ---
const susp = canvas.slice(canvas.indexOf('private suspendTextEditing()'),
  canvas.indexOf('private suspendTextEditing()') + 1400);
check(susp.includes('this.onTextCommit(this.editingDraftText)'),
  'suspend still commits the draft (uke.d tail → mub write)');
check(susp.includes('.then(') &&
  susp.indexOf('.then(') > susp.indexOf('this.onTextCommit(this.editingDraftText)') &&
  susp.includes('this.suspendedCaretByBlock.set(block.id, caret)'),
  'suspend records the caret after the commit resolves (session retained)');
check(susp.indexOf('const block') < susp.indexOf('this.onTextCommit('),
  'block/caret captured before commit clears editing state');

// --- 会话恢复：beginTextEditingAt 命中块 → 取挂起光标 ---
const begin = canvas.slice(canvas.indexOf('private beginTextEditingAt('),
  canvas.indexOf('private beginTextEditingAt(') + 1600);
check(begin.includes('this.suspendedCaretByBlock.get(') &&
  begin.includes('this.textEditingRestoreCaret'),
  're-activation looks up the suspended caret (uke.p get parity)');

// --- 显式销毁（oke/Done/Cancel）清除挂起条目 ---
const commit = canvas.slice(canvas.indexOf('async onTextCommit('),
  canvas.indexOf('async onTextCommit(') + 8600);
check(commit.includes('this.suspendedCaretByBlock.delete('),
  'explicit commit destroys the suspended session entry');
const cancel = canvas.slice(canvas.indexOf('onTextCancel(): void'),
  canvas.indexOf('onTextCancel(): void') + 2200);
check(cancel.includes('this.suspendedCaretByBlock.delete('),
  'cancel destroys the suspended session entry');

// --- 页面切换清空挂起会话（uke.p 文档作用域） ---
check(canvas.includes('this.suspendedCaretByBlock.clear()'),
  'page load clears suspended sessions');

// --- 覆盖层：caret 跟踪 + 恢复 ---
check(overlay.includes('controller: this.controller') &&
  overlay.includes('TextAreaController'),
  'TextArea wired to a TextAreaController');
check(overlay.includes('onTextSelectionChange') &&
  overlay.includes('this.onCaretChange(end)'),
  'caret tracked via selection-end callback');
check(overlay.includes('this.controller.caretPosition(') &&
  overlay.includes('this.restoreCaret'),
  'suspended caret restored on appear (pke session resume)');

// --- 画布接线：restoreCaret prop + onCaretChange 回写 ---
check(canvas.includes('restoreCaret: this.textEditingRestoreCaret') &&
  canvas.includes('this.editingCaretOffset = offset'),
  'canvas feeds restoreCaret and records live caret');

console.log(`D02_ORIGINAL_TEXTEDIT_SUSPEND_OK TOTAL=${n} FAILED=0`);
