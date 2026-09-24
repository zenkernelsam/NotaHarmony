// Phase 696 — 原版空装饰段 Enter + 列表段 Tab（fm7.g/fm7.h/l8j/n4c）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{fm7,l8j,n4c,qi3,h5a}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const fm7 = read(`${SRC}/sources/defpackage/fm7.java`);
check(fm7.includes('clearDecoratorOnCursorParagraph'),
  'fm7.c(): clearDecoratorOnCursorParagraph');
check(fm7.includes('o(ys2.P(new h5a(-1)))'),
  'fm7.g(): empty list paragraph indent>0 -> h5a(-1) outdent');
check(fm7.includes('l("\\n", null)') || fm7.includes('l("\n", null)'),
  'fm7.g(): fallback inserts "\\n"');
check(fm7.includes('o(ys2.P(new h5a(1)))'),
  'fm7.h(): list paragraph Tab -> h5a(+1) indent');
check(fm7.includes('l("\\t", null)') || fm7.includes('l("\t", null)'),
  'fm7.h(): fallback inserts "\\t" via replaceSelectedText');

const l8j = read(`${SRC}/sources/defpackage/l8j.java`);
check(l8j.includes('qi3Var.c()') && l8j.includes('n4c.x(qi3Var.i)'),
  'l8j.h: requires empty paragraph (qi3.c) + list decorator (n4c.x)');
check(l8j.includes('n4c.w(qi3Var.i)'),
  'l8j.i: quote/code decorator (n4c.w)');

const n4c = read(`${SRC}/sources/defpackage/n4c.java`);
check(n4c.includes('fy2.CODE_BLOCK || fy2Var == fy2.BLOCK_QUOTE'),
  'n4c.w = BLOCK_QUOTE | CODE_BLOCK');
check(n4c.includes('fy2.BULLET || fy2Var == fy2.NUMBER || fy2Var == fy2.CHECK_BOX'),
  'n4c.x = BULLET | NUMBER | CHECK_BOX');

const qi3 = read(`${SRC}/sources/defpackage/qi3.java`);
check(qi3.includes("str.charAt(i) != '\\n'"),
  'qi3.c() = paragraph content all-newline (empty)');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('.onWillInsert((info: InsertValue): boolean =>'),
  'overlay: onWillInsert attached');
check(overlay.includes('private onWillInsertText(info: InsertValue): boolean'),
  'overlay: onWillInsertText handler');
check(overlay.includes("info.insertValue !== '\\n'"),
  'overlay: only "\\n" intercepted');
check(overlay.includes('private isParagraphEmpty(offset: number): boolean'),
  'overlay: isParagraphEmpty = qi3.c() equivalent');
check(/decorator >= 1 && decorator <= 3/.test(overlay),
  'overlay: list decorators 1-3 = n4c.x');
check(overlay.includes('this.adjustIndentLevel(-1)') &&
  overlay.includes('this.clearParagraphDecorator(paragraphIndex)'),
  'overlay: empty list Enter -> outdent (indent>0) or clear decorator (==0)');
check(/decorator === 4 \|\| decorator === 5/.test(overlay),
  'overlay: quote/code decorators 4/5 = n4c.w');
check(overlay.includes('private clearParagraphDecorator(paragraphIndex: number): void'),
  'overlay: clearParagraphDecorator = fm7.c()');
check(overlay.includes('private handleTabKey(): boolean'),
  'overlay: handleTabKey = fm7.h');
check(overlay.includes('event.keyCode === 2049') &&
  overlay.includes('return this.handleTabKey()'),
  'overlay: KEYCODE_TAB 2049 routed');
check(overlay.includes('this.adjustIndentLevel(1)'),
  'overlay: list Tab -> h5a(+1) indent');
check(overlay.includes("oldText.slice(0, s) + '\\t' + oldText.slice(e)") &&
  overlay.includes('this.adjustCharRunsForEdit(this.draftText, oldText)'),
  'overlay: non-list Tab -> replace selection with tab char (l("\\t"))');
check(overlay.includes('this.controller.caretPosition(s + 1)') &&
  overlay.includes('this.onDraftChange(this.draftText)'),
  'overlay: tab insert moves caret + syncs draft');

console.log(`D02_ORIGINAL_LIST_ENTER_TAB_REPLAY_OK TOTAL=${total} FAILED=0`);
