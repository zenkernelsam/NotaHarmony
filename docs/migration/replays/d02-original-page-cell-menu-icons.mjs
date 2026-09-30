// Desktop Replay — Phase 1378：页缩略图长按菜单项图标。
// PageOverviewPanel.buildCellMenu 的每个页操作 MenuItem 现在携带
// startIcon（映射自 n9j/fd2 原版页菜单的 h1a painter 图标）。
// 验证图标绑定 + 每个动作回调与门控保持原语义。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/PageOverviewPanel.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

// ── 结构：buildCellMenu 仍是 Menu + MenuItem ───────────────────────
const menu = src.match(/private buildCellMenu\(\)[\s\S]*?\n  \}\n/);
ok(menu !== null, 'buildCellMenu exists');
const body = menu ? menu[0] : '';

// 每个页操作项的 startIcon 映射（原版 n9j/fd2 图标 → media SVG）
const cases = [
  ['add_page', 'menuicon_add_page'],
  ['cut_page', 'selmenu_cut'],
  ['copy_page', 'selmenu_copy'],
  ['paste_page', 'selmenu_paste'],
  ['duplicate_page', 'selmenu_duplicate'],
  ['rotate_page', 'menuicon_rotate_page'],
  ['clear_page', 'menuicon_clear_page'],
  ['delete_page', 'selmenu_delete'],
  ['pages_menu_select', 'menuicon_select_circle'],
];
for (const [label, icon] of cases) {
  const re = new RegExp(`MenuItem\\(\\{ content: \\$r\\('app\\.string\\.${label}'\\), startIcon: \\$r\\('app\\.media\\.${icon}'\\) \\}\\)`);
  ok(re.test(body), `${label} → ${icon}`);
}

// ── 动作回调保持原语义 ─────────────────────────────────────────────
const actions = [
  ["'add'"], ["'cut'"], ["'copy'"], ["'paste'"], ["'duplicate'"],
  ["'rotate'"], ["'clear'"], ["'delete'"],
];
for (const [act] of actions) {
  ok(body.includes(`onMenuAction(this.pageIndex, ${act})`), `action ${act} preserved`);
}
ok(body.includes('onToggleSelect(this.pageIndex)'), 'select action preserved');
// 门控保持：paste 仅在 canPaste，rotate 仅在可旋转页
ok(/if \(this\.canPaste\)[\s\S]*?paste_page/.test(body), 'paste gated by canPaste');
ok(/rotatedOriginalPageInfo\(this\.page\) !== null[\s\S]*?rotate_page/.test(body), 'rotate gated by rotatedOriginalPageInfo');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
