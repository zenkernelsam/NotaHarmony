// Phase 1387 — 1.0.3↔1.4.2 版本差异 Replay。
// 断言证据文档记录了 1.4.2 大版本跃进的关键事实：规模、新组件/权限、
// 新特性（Learn/社区图库/Shape/Calligraphy/贴纸/模板）与移植分类。
// 用法：node d02-1-4-2-version-diff.mjs  → CTX_GREEN + PASS=N FAIL=0
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '../../..');
const ev = readFileSync(join(ROOT, 'docs/migration/evidence/phase-1387-1-4-2-version-diff.md'), 'utf8');

const checks = [
  ['版本对 1.0.3/1014 ↔ 1.4.2/1040002', /1\.0\.3/.test(ev) && /1\.4\.2/.test(ev) && /1040002/.test(ev)],
  ['规模 +3700 源', /\+3,?700/.test(ev) || /24808/.test(ev)],
  ['字符串 +722', /722/.test(ev)],
  ['HwrEngineService 新组件', /HwrEngineService/.test(ev)],
  ['READ_CALENDAR 新权限', /READ_CALENDAR/.test(ev)],
  ['Shape 工具', /shape_tool|Shape 工具/.test(ev)],
  ['Calligraphy 笔刷样式', /[Cc]alligraphy/.test(ev)],
  ['贴纸', /stickers|贴纸/.test(ev)],
  ['Learn/AI 学习套件', /feature_learn|Learn/.test(ev)],
  ['社区图库', /feature_library_gallery|社区图库/.test(ev)],
  ['付费墙/订阅 fail-closed', /paywall|付费墙/.test(ev)],
  ['本地可移植分类 A', /本地可移植/.test(ev)],
  ['后端依赖分类 B', /后端依赖/.test(ev)],
];

let pass = 0; const fails = [];
for (const [name, ok] of checks) { if (ok) pass++; else fails.push(name); }
console.log('CTX_GREEN');
console.log(`PASS=${pass} FAIL=${fails.length}`);
if (fails.length) { console.log('FAILED:'); for (const f of fails) console.log(' - ' + f); process.exitCode = 1; }
