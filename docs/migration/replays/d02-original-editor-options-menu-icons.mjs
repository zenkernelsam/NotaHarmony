// Desktop Replay — Phase 1381：编辑器 ⋮ 选项菜单项图标。
// NotePage.buildEditorOptionsMenu（原版 o94 case14 编辑器选项菜单）的
// MenuElement 现在携带 icon：hide/reveal_tapes 动态胶带图标（反映当前态）、
// options_menu_app_settings → 齿轮。验证图标绑定 + 动作语义保持。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/NotePage.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

const menu = src.match(/private buildEditorOptionsMenu\(\)[\s\S]*?return items;/);
ok(menu !== null, 'buildEditorOptionsMenu exists');
const body = menu ? menu[0] : '';

// 图标映射（原版 o94 279/283 + settings gear）
ok(/hide_tapes.*reveal_tapes[\s\S]*?icon: this\.anyTapeRevealed[\s\S]*?menuicon_tape_reveal[\s\S]*?menuicon_tape_conceal/
  .test(body), 'tapes icon reflects current state (hide→reveal, reveal→conceal)');
ok(/options_menu_app_settings'[\s\S]*?icon: \$r\('app\.media\.menuicon_settings'\)/.test(body),
  'app_settings → menuicon_settings (gear outline)');

// 门控/动作语义保持
ok(body.includes('if (this.pageTapeCount > 0)'), 'tapes row gated by pageTapeCount');
ok(body.includes('this.tapeToggleSignal++'), 'tape toggle signal kept');
ok(body.includes('this.navigateToSettings()'), 'navigateToSettings action kept');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
