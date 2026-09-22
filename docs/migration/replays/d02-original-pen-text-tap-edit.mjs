// Phase 623 — TEXT 面裸笔点按文本块直接编辑（zl2 case25 的 xtc.c 路径）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   zl2.java case25 — TEXT 面点按分发：
//     qo5VarC = xtcVar.c(jE)        // xhe 过滤命中（文本元素）
//     hit → qke(qo5)               // 直接编辑会话（uke.d 产出）
//     miss + tl7.w(page, y)        // 命中含链接行 → return null 吞掉
//     miss otherwise               // oke.a → 提交/销毁会话
//   xtc.java:76 — c(j)：vnd 命中过滤 instanceof xhe（文本承载元素）。
//   tl7.java:823 — w(page,y)：y 处文本行含链接内容 → true。
//   dl1.java:87 — z && !elh.h（裸笔、无桶键）→ z3=false：rtc/vtc
//     选区命中压制为 utc，落空交还文本手势面（即 case25 路径）。
// Harmony 对齐：DEFAULT（文本面）下裸笔点按此前落进双击计时器——
//   点按已存在文本块也要等第二击才进入编辑，与原版单笔点按 qke
//   直接编辑不一致。对齐：stylusSuppress 分支先做 xhe 等价命中
//   （顶层优先 pointHitsTextBlock 循环）——命中且无链接 →
//   beginTextEditingAt 直接编辑；命中链接行 → 吞掉；落空保持
//   双击创建路径。手指点按仍经选区分发（vtc），不经此支。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- zl2 case25 等价分支：裸笔 + TEXT 面 → 文本命中直接编辑 ---
const sIdx = view.indexOf('if (stylusSuppress) {');
check(sIdx > 0, 'stylusSuppress text-gesture branch present');
const s = view.slice(sIdx, sIdx + 1400);
check(s.includes('pointHitsTextBlock(canvasP, this.textBlocks[i])'),
  'xhe-filtered hit: topmost-first pointHitsTextBlock loop (xtc.c parity)');
check(s.includes('this.linkHitOnTextBlock(this.textBlocks[i].id, canvasP) === null'),
  'link-line hit swallowed (tl7.w parity — no edit, no create)');
check(s.includes('this.beginTextEditingAt(canvasP)'),
  'text-block hit → beginTextEditingAt direct edit (qke parity, single tap)');
check(s.includes('this.lastTapTime = 0'),
  'tap timer reset so the edit is not confused with double-tap create');
check(s.includes('penTextHit'),
  'penTextHit guard: only consumes when a text block is actually hit');

// --- 分支顺序：压制分支在双击计时器之前 ---
const dIdx = view.indexOf('const now: number = Date.now();\n      const dx: number = touch.x - this.lastTapPos.x;');
check(dIdx > 0 && sIdx < dIdx,
  'pen text-hit dispatch precedes the double-tap create path (oke.a fallback)');

// --- 手指路径不受影响：选区分发仍先行 ---
const selIdx = view.indexOf('if (!stylusSuppress) {');
check(selIdx > 0 && selIdx < sIdx,
  'finger taps still run selection dispatch first (z3 allowed path)');

// --- beginTextEditingAt 仍是文本块激活入口 ---
const bIdx = view.indexOf('private beginTextEditingAt(');
check(bIdx > 0, 'beginTextEditingAt present');
const b = view.slice(bIdx, bIdx + 1600);
check(b.includes('pointHitsTextBlock(position, this.textBlocks[i])') &&
  b.includes('this.editingTextBlock = this.textBlocks[i]'),
  'beginTextEditingAt activates the hit block (qke → uke.d parity)');
check(b.includes('this.createTextBlockAt(position)'),
  'empty-area fallback still creates a block (double-tap path unchanged)');

console.log(`D02_ORIGINAL_PEN_TEXT_TAP_EDIT_OK TOTAL=${n} FAILED=0`);
