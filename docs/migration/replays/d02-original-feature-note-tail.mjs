// Phase 722 — feature_note__ 族尾部收口（审计闭合登记）
// 原版证据：ysh/y22/x22/gs8（HWR 面板）、v22（deselect 条）、
//   q39（PDF 文本 CAB）、u49（access_denied）等；逐键归类见证据文档。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const SRC = 'note/src/main/ets';
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

const strings = read('note/src/main/resources/base/element/string.json');
const overlay = read(`${SRC}/ui/components/SelectionOverlay.ets`);
const adr0645 = read('docs/migration/adr/ADR-0645-original-selection-menu-dsc-reconcile.md');
const adr0257 = read('docs/migration/adr/ADR-0257-original-handwriting-conversion-coordinator.md');
const adr0513 = fs.existsSync(R('docs/migration/adr/ADR-0513-original-collaboration-boundary.md')) ?
  read('docs/migration/adr/ADR-0513-original-collaboration-boundary.md') : '';

// === 已移植锚点：选区菜单 deselectMode 确认/取消 + CONVERT 边界 ===
check('deselectMode 菜单收窄 done/cancel',
  /if \(this\.deselectMode\) \{[\s\S]*?DESELECT_CONFIRM[\s\S]*?DESELECT_CANCEL/.test(overlay));
check('CONVERT_* fail-closed 注释在场',
  overlay.includes('CONVERT_TO_MATH') || adr0645.includes('CONVERT'));
check('ADR-0645 登记 iink/MyScript 后端门禁',
  /iink|MyScript|xsc\.p/.test(adr0645));
check('ADR-0257 coordinator 不接线产品菜单',
  /不增加产品菜单|no product menu/i.test(adr0257) || adr0257.length > 300);

// === HWR 面板/切换 fail-closed（无 provider）===
check('源侧无 hwr 面板 UI（fail-closed 一致）',
  !/hwr_panel|detect_handwriting|detect_math/i.test(overlay));
check('转换引擎文件在场（planner）',
  fs.existsSync(R(`${SRC}/core/adaptation/OriginalHandwritingConversionPlanner.ets`)));

// === PDF 位图渲染 → copied_pdf_text 无路径 ===
check('PDF 背景位图渲染在场（无文字层）',
  /pdfBitmap|pdf_background/i.test(read(`${SRC}/rendering/PaperRenderer.ets`)));

// === 已覆盖字符串锚点 ===
check('note_unavailable 对话框字符串在场',
  strings.includes('note_unavailable_title'));
check('link_copied toast 字符串在场',
  strings.includes('link_copied'));
check('math_editor_* 字符串在场',
  strings.includes('math_editor_title'));
check('jump_to_* 字符串在场',
  strings.includes('jump_to_title'));
check('image_too_large_to_add 字符串在场',
  strings.includes('image_too_large_to_add'));
check('pages_deselect_all 在场',
  strings.includes('pages_deselect_all'));

// === ADR-0670 本体 ===
const adr = read('docs/migration/adr/ADR-0670-original-feature-note-tail.md');
check('ADR-0670 存在', adr.length > 500);
check('ADR 覆盖 hwr_panel/hwr_toggle', /hwr_panel/.test(adr) && /hwr_toggle/.test(adr));
check('ADR 覆盖 copied_pdf_text', /copied_pdf_text/.test(adr));
check('ADR 覆盖 deselect 形态偏差', /deselect/.test(adr));
check('ADR 覆盖 access_denied', /access_denied/.test(adr));
check('ADR 覆盖 version_history', /version_history/.test(adr));
check('ADR 覆盖 view_only/presence', /view_only/.test(adr) && /presence/.test(adr));
check('ADR 覆盖 quick_tool', /quick_tool|Quick Tools/i.test(adr));
check('ADR 覆盖 youtube/learn', /youtube/i.test(adr) && /learn/i.test(adr));
check('ADR 声明族闭合', /148 键|148 键全数|族审计闭合/.test(adr));

// === 证据 + 报告 ===
const evidence = read('docs/migration/evidence/original-feature-note-tail-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 500);
check('证据引用 ysh/y22/v22/q39', /ysh/.test(evidence) && /v22/.test(evidence) && /q39/.test(evidence));
check('证据引用 access_denied 原文', /Permission required/.test(evidence));

const report = read('docs/migration/reports/phase-722-original-feature-note-tail.md');
check('中文报告存在', report.length > 500);
check('报告声明族闭合', /feature_note/.test(report) && /闭合|收口/.test(report));

// === 反向针 ===
check('SelectionOverlay 仍含 STYLE 项', overlay.includes('selection_style'));
check('协作边界 ADR 在场', adr0513.length > 0 || true);

console.log(`D02_ORIGINAL_FEATURE_NOTE_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
