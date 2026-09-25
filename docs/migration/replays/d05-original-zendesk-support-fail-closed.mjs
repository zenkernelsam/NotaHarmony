// D05 原版 Zendesk 帮助/支持中心 fail-closed — Phase 711
// （ADR-0659）。原版 ui_support__* FAQ+工单面全部走
// global/zendesk/v2/* 私有代理；Harmony 无该后端、无入口。
import { readFileSync, readdirSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const api = read(`${JADX}/sources/com/gingerlabs/notability/ui/support/data/a.java`);
const q31 = read(`${JADX}/sources/defpackage/q31.java`);
const q0 = read(`${JADX}/sources/defpackage/q0.java`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版字符串面 ---
for (const s of ['faqs_header', 'faq_general', 'faq_getting_started',
  'faq_reported_issues', 'tab_contact', 'issue_header', 'issue_app_crashes',
  'issue_data_loss', 'issue_handwriting', 'issue_syncing', 'subject_header',
  'description_header', 'email_header', 'submit', 'submitting',
  'success_title', 'visit_help_center', 'add_photo', 'error_upload_failed',
  'disclaimer_prefix', 'privacy_policy', 'search_placeholder']) {
  check(strings.includes(`ui_support__${s}`), `strings ui_support__${s}`);
}

// --- 后端面：私有 Zendesk 代理 ---
check(api.includes('global/zendesk/v2/help_center/articles/search.json'),
  'FAQ 搜索走 global/zendesk/v2 代理');
check(api.includes('global/zendesk/v2/requests.json'), '工单提交 requests.json');
check(api.includes('global/zendesk/v2/uploads.json'), '附件上传 uploads.json');
check(q31.includes('ui_support__faqs_header'), 'q31 渲染 FAQ sections');
check(q0.includes('lc4.a(ac4.U0)') && q0.includes('jeh.f'),
  '入口行经 ac4.U0 门控（ADR-0658）');

// --- Harmony 侧：旗标关闭态 ---
const walk = (dir) => readdirSync(dir, { withFileTypes: true })
  .flatMap((e) => e.isDirectory() ? walk(`${dir}/${e.name}`) :
    e.name.endsWith('.ets') ? [`${dir}/${e.name}`] : []);
const etsFiles = walk('note/src/main/ets');
for (const f of etsFiles) {
  check(!/zendesk|helpCenter|supportTicket/i.test(read(f)),
    `${f.split('/').pop()} 无 Zendesk/帮助中心实现`);
}
check(!read('note/src/main/resources/base/element/string.json')
  .includes('ui_support'), 'Harmony 字符串无 ui_support 条目');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0659-original-zendesk-support-failclosed.md')
  .includes('zendesk/v2'), 'ADR-0659 声明 Zendesk 代理边界');
check(read('docs/migration/evidence/original-zendesk-support-jadx-2026-09-25.md')
  .includes('requests.json'), '证据文档记录工单端点');

console.log(`D05_ORIGINAL_ZENDESK_SUPPORT_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
