// Desktop Replay — Phase 1380：工具箱设置工具菜单项图标。
// ToolboxSettingsDialog.toolMenu（原版 o94/xc2 工具上下文菜单行）的
// MenuElement 现在携带 icon；验证图标映射 + 动作/门控语义保持。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

const menu = src.match(/private toolMenu\(tool: ToolState\)[\s\S]*?\n    return items;/);
ok(menu !== null, 'toolMenu exists');
const body = menu ? menu[0] : '';

// 原版图标映射（o94/xc2）：
//   hide_tool → ui_designsystem__hide
//   duplicate_tool → ui_designsystem__duplicate
//   delete_tool → ui_designsystem__trash（xc2 z2 分支）
//   hide_tapes → ui_tools__tape_reveal（图标反映当前态）
//   reveal_tapes → ui_tools__tape_conceal
ok(/value: \$r\('app\.string\.hide_tool'\),\s*icon: \$r\('app\.media\.menuicon_hide'\)/.test(body),
  'hide_tool → menuicon_hide');
ok(/value: \$r\('app\.string\.duplicate_tool'\),\s*icon: \$r\('app\.media\.selmenu_duplicate'\)/.test(body),
  'duplicate_tool → selmenu_duplicate');
ok(/value: \$r\('app\.string\.delete_tool'\),\s*icon: \$r\('app\.media\.selmenu_delete'\)/.test(body),
  'delete_tool → selmenu_delete');
ok(/hide_tapes.*reveal_tapes[\s\S]*?icon: this\.anyTapeRevealed[\s\S]*?menuicon_tape_reveal[\s\S]*?menuicon_tape_conceal/
  .test(body), 'tapes icon reflects current state (hide→reveal, reveal→conceal)');

// Harmony 适配项不带原版图标（move_to_* / tape_patterns 为适配/子页导航）。
ok(/value: tool\.trayType === TRAY_TYPE_PRIMARY[\s\S]*?action:[\s\S]*?\},\s*\{[\s\S]*?hide_tool/.test(body) &&
   !/move_to_(primary|secondary)'\),\s*icon:/.test(body),
  'move_to_primary/secondary iconless (Harmony adaptation)');

// 动作/门控语义保持
ok(body.includes('this.viewModel.hideTool(tool.toolId)'), 'hideTool action kept');
ok(body.includes('this.viewModel.duplicateTool(tool.toolId)'), 'duplicateTool action kept');
ok(body.includes('this.viewModel.deleteTool(tool.toolId)'), 'deleteTool action kept');
ok(body.includes('this.onTapeToggle()'), 'tape toggle action kept');
ok(body.includes('this.viewModel.canDeleteTool(tool.toolId)'), 'delete gated by canDeleteTool');
ok(body.includes('if (this.tapeCount > 0)'), 'tapes row gated by tapeCount');
ok(body.includes('tool.toolType === ToolType.REVIEW'), 'tape rows gated by REVIEW type');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
