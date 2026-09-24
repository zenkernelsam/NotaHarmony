// Phase 697 — 原版粘贴 URL 自动转链接（fm7.j/jvi.d）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{fm7,jvi}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const fm7 = read(`${SRC}/sources/defpackage/fm7.java`);
check(fm7.includes('pasteFromClipboard'),
  'fm7.j(): pasteFromClipboard op');
check(fm7.includes('lvd.d1(string)'),
  'fm7.j(): clipboard text trimmed via lvd.d1');
check(fm7.includes('jvi.d(string2)'),
  'fm7.j(): trimmed text URL-checked via jvi.d');
check(fm7.includes('zydVar != null'),
  'fm7.j(): URL paste swaps visible text to trimmed + link style');

const jvi = read(`${SRC}/sources/defpackage/jvi.java`);
check(jvi.includes('URLUtil.isValidUrl(str) || Patterns.WEB_URL.matcher(str).matches()'),
  'jvi.d: URLUtil.isValidUrl || WEB_URL match gate');
check(jvi.includes('"https://".concat(str)'),
  'jvi.d: scheme-less URL gets https:// prefix');
check(jvi.includes('lowerCase.equals("http") || lowerCase.equals("https")'),
  'jvi.d: http/https schemes pass through');
check(jvi.includes('return null;'),
  'jvi.d: other schemes / non-URL -> null');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('.onPaste((value: string, event: PasteEvent): void =>'),
  'overlay: onPaste attached to TextArea');
check(overlay.includes('private onTextPaste(value: string, event: PasteEvent): void'),
  'overlay: onTextPaste handler');
check(overlay.includes('event.preventDefault()'),
  'overlay: URL paste cancels native insert');
check(overlay.includes('private pastedUrlOrNull(raw: string): string'),
  'overlay: pastedUrlOrNull = jvi.d equivalent');
check(overlay.includes('raw.trim()') && overlay.includes('/\\s/.test(t)'),
  'overlay: trim + whitespace rejection (fm7.j lvd.d1)');
check(overlay.includes("scheme !== 'http' && scheme !== 'https'"),
  'overlay: non-http(s) schemes rejected (jvi.d)');
check(overlay.includes("'https://' + t"),
  'overlay: scheme-less URL gets https:// prefix');
check(overlay.includes('const title: string = value.trim()'),
  'overlay: inserted visible text = trimmed paste');
check(overlay.includes('this.applyLinkUrl(url, s, s + title.length)') &&
  overlay.includes('this.normalizeCharRuns()'),
  'overlay: link style applied via applyLinkUrl + runs normalized');
check(overlay.includes('this.controller.caretPosition(s + title.length)') &&
  overlay.includes('this.onDraftChange(this.draftText)'),
  'overlay: caret lands after inserted link + draft synced');
check(overlay.includes('this.photoImportLeaseActive'),
  'overlay: paste interception gated by photo-import lease');

console.log(`D02_ORIGINAL_PASTE_URL_LINK_REPLAY_OK TOTAL=${total} FAILED=0`);
