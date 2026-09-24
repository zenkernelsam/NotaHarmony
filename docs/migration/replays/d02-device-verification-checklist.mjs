// Phase 571 — P1(d) consolidated real-device verification checklist.
// The handover requires a single table aggregating every "must verify on a
// real device" item so the first simulator/device session has a ready
// high-priority checklist. This replay pins the checklist's existence,
// section coverage, row count, and per-row ADR/Phase references.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CHECKLIST = 'docs/migration/audit-2026-08/真机验收清单-2026-09-22.md';
const doc = readFileSync(CHECKLIST, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- File exists with required structure ---
check(doc.includes('真机验收清单'), 'title');
check(doc.includes('P1(d)'), 'handover reference');

// --- All 9 subsystem sections present ---
const sections = ['手写与画布渲染', '数学公式', '图片与素材', '录音与音频',
  'PDF 与页面', '备份 / 导入导出 / WebDAV 同步', '编辑器生命周期与竞态',
  '资料库与系统交互', '设置与系统栏'];
for (const s of sections) {
  check(doc.includes(`## `) && doc.includes(s), `section: ${s}`);
}

// --- Every table row carries an ADR/Phase reference ---
const rows = doc.split('\n').filter(l => /^\| (R|M|I|A|P|S|L|B|E)-\d+ \|/.test(l));
check(rows.length >= 68, `row count (${rows.length} >= 68)`);
for (const row of rows) {
  check(/ADR-\d{4}|Phase \d{3}/.test(row), `row cites evidence: ${row.slice(0, 40)}`);
}

// --- Coverage anchors: recent phases must be registered ---
const anchors = ['ADR-0539', 'ADR-0540', 'ADR-0541', 'ADR-0531', 'ADR-0532',
  'ADR-0533', 'ADR-0535', 'ADR-0534', 'ADR-0538', 'ADR-0502', 'ADR-0127',
  'ADR-0185', 'ADR-0167', 'ADR-0081',
  // Phase 676 补遗：572~675 新增运行态项
  'ADR-0572', 'ADR-0580', 'ADR-0594', 'ADR-0599', 'ADR-0618', 'ADR-0619',
  'ADR-0620', 'ADR-0621', 'ADR-0622', 'ADR-0628', 'ADR-0631', 'ADR-0632',
  'ADR-0633', 'ADR-0640', 'ADR-0641'];
for (const a of anchors) {
  check(doc.includes(a), `checklist covers ${a}`);
}

// --- Phase 676 补遗 section registered ---
check(doc.includes('Phase 676 补遗'), 'phase-676 appendix section');

// --- Maintenance rule present ---
check(doc.includes('同步登记'), 'maintenance rule');

console.log(`D02_DEVICE_VERIFICATION_CHECKLIST_REPLAY_OK TOTAL=${n} FAILED=0`);
