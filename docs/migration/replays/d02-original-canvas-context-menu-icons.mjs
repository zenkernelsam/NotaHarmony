// Desktop Replay — Phase 1379：画布空白处长按菜单项图标。
// NoteCanvasView.ClipboardPasteContextMenu（原版 yqa.f 空白长按 {PASTE,
// SELECT_ALL}）的 MenuItem 现在携带 startIcon；验证图标绑定 + 门控与
// 动作语义保持原样。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/NoteCanvasView.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

const menu = src.match(/private ClipboardPasteContextMenu\(\)[\s\S]*?\n  \}\n/);
ok(menu !== null, 'ClipboardPasteContextMenu exists');
const body = menu ? menu[0] : '';

// 图标绑定
ok(/MenuItem\(\{ content: \$r\('app\.string\.paste'\), startIcon: \$r\('app\.media\.selmenu_paste'\) \}\)/
  .test(body), 'paste → selmenu_paste');
ok(/MenuItem\(\{ content: \$r\('app\.string\.select_all'\), startIcon: \$r\('app\.media\.menuicon_select_all'\) \}\)/
  .test(body), 'select_all → menuicon_select_all');

// 门控保持：paste 仅在剪贴板/系统图片可用，外层 recentInteractionGate
ok(/canPasteClipboardNow\(\) \|\| this\.canUseOriginalClipboardImage\(\)[\s\S]*?paste/.test(body),
  'paste gated by clipboard/image availability');
ok(body.includes('recentInteractionGateActive()'), 'outer recentInteractionGate kept');

// 动作语义保持
ok(body.includes('this.pasteClipboard(target)'), 'element-clipboard paste path kept');
ok(body.includes('this.startOriginalClipboardImagePaste()'), 'system-image paste path kept');
ok(body.includes('this.selectAllPageElements()'), 'select-all callback kept');
ok(body.includes('if (this.photoImportBusy)'), 'paste photoImportBusy guard kept');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
