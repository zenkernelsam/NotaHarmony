// Desktop Replay — Phase 1383：工具栏内联插入按钮挂原版图标 + add_files 映射校正。
// 原版 qc.java：插入动作是 apb.f icon+label 下拉项（add_files→paper_plain_outline、
// add_photo→insert_media_fill_outline、take_photo→camera_outline、insert_math→
// insert_math）。Harmony 宽屏内联按钮改用 InsertButton(icon+label)，
// 紧凑菜单 add_files 图标由 attach_file 校正为 paper_plain_outline。
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets'), 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; } else { fail++; console.error('FAIL', name); } };

// InsertButton 助手存在且渲染 icon+label
ok(/@Builder\s*\n?\s*private InsertButton\(label: ResourceStr, icon: ResourceStr/.test(src),
  'InsertButton builder exists with (label, icon)');
ok(/Image\(icon\)[\s\S]*?\.fillColor\(this\.resolveTokens\(\)\.textPrimary\)/.test(src),
  'InsertButton renders Image(icon) tinted textPrimary');
ok(/Text\(label\)/.test(src), 'InsertButton renders Text(label)');

// 4 个内联插入按钮的图标映射（qc.java 证据）
const cases = [
  ["add_files", "menuicon_paper", "onAddFiles()"],
  ["insert_photo", "menuicon_insert_media", "onInsertPhotos()"],
  ["take_photo", "menuicon_camera", "onTakePhoto()"],
  ["insert_math", "menuicon_insert_math", "onInsertMath()"],
];
for (const [label, icon, cb] of cases) {
  const re = new RegExp(`InsertButton\\(\\$r\\('app\\.string\\.${label}'\\), \\$r\\('app\\.media\\.${icon}'\\),\\s*\\(\\) => this\\.${cb.replace('()','\\(\\)')}\\)`);
  ok(re.test(src), `${label} → ${icon} → ${cb}`);
}

// 紧凑菜单 add_files 图标校正为 paper_plain_outline（不再是 attach_file）
const menuStart = src.indexOf('private buildCompactToolMenu()');
const menu = src.slice(menuStart, src.indexOf('StateToolButton', menuStart));
ok(/add_files'\), icon: \$r\('app\.media\.menuicon_paper'\)/.test(menu),
  'compact-menu add_files → menuicon_paper (paper_plain_outline)');
ok(!/add_files'\), icon: \$r\('app\.media\.menuicon_attach_file'\)/.test(menu),
  'add_files no longer uses attach_file');

// InsertButton 保留 enabled + lease guard
ok(/private InsertButton[\s\S]*?\.enabled\(!this\.viewModel\.toolStateLoading &&\s*!this\.photoImportLeaseActive\)[\s\S]*?if \(this\.photoImportLeaseActive\)/.test(src),
  'InsertButton keeps enabled + photoImportLeaseActive guard');

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
