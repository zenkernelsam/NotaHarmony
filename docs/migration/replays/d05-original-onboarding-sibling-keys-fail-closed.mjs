// D05 原版 hq9 兄弟 datastore 键 fail-closed — Phase 713（ADR-0661）。
// onboardingTooltipSeen 已由 Phase 712 移植；剩余两键：
//   defaultNotesRolePromptSeen      → 共享笔记角色提示（协作后端）
//   sixMonthsPlusOnboardingSeenUserIds → "6 months of Plus" 促销弹窗（账号/订阅）
// 两者均不可移植，Harmony 正确行为为缺席。
import { readFileSync, readdirSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const hq9 = read(`${JADX}/sources/defpackage/hq9.java`);
const gq9 = read(`${JADX}/sources/defpackage/gq9.java`);
const s89 = read(`${JADX}/sources/defpackage/s89.java`);
const m8 = read(`${JADX}/sources/defpackage/m8.java`);
const h3 = read(`${JADX}/sources/defpackage/h3.java`);
const ccj = read(`${JADX}/sources/defpackage/ccj.java`);
const tt8 = read(`${JADX}/sources/defpackage/tt8.java`);
const q31 = read(`${JADX}/sources/defpackage/q31.java`);
const cha = read(`${JADX}/sources/defpackage/cha.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版 datastore 键与模型 ---
check(hq9.includes('sixMonthsPlusOnboardingSeenUserIds'),
  'hq9 定义 sixMonthsPlusOnboardingSeenUserIds 键');
check(gq9.includes('seenDefaultNotesRolePrompt') &&
  gq9.includes('seenSixMonthsPlusOnboardingUserIds') &&
  gq9.includes('tooltipStatus'), 'gq9 三字段 seen 模型');
check(/gq9\.c|gq9Var\.c/.test(s89) && /gq9Var2\.b|gq9\.b/.test(s89),
  's89 暴露 gq9.c/gq9.b 流');

// --- notes_role_* 提示面（协作角色） ---
for (const s of ['notes_role_prompt_title', 'notes_role_prompt_message',
  'notes_role_prompt_confirm', 'notes_role_prompt_deny',
  'notes_role_info_message', 'notes_role_info_dismiss']) {
  check(strings.includes(`feature_library__${s}`), `strings ${s}`);
}
check(m8.includes('notes_role_prompt_title'), 'm8 渲染角色提示标题');
check(h3.includes('notes_role_info_message') && h3.includes('notes_role_prompt_message'),
  'h3 双形态 message（prompt/info）');
check(ccj.includes('notes_role_prompt_confirm') && ccj.includes('notes_role_info_dismiss'),
  'ccj 渲染 confirm/dismiss 按钮');
check(cha.includes('userAccessLevel') && cha.includes('linkPermissionScope'),
  '角色状态源自 SyncedNoteMetadata 协作字段');

// --- six_months_plus 促销弹窗（账号/订阅） ---
check(strings.includes('ui_designsystem__six_months_plus_onboarding_title') &&
  strings.includes('ui_designsystem__six_months_plus_onboarding_description'),
  'six_months_plus 弹窗字符串');
check(tt8.includes('six_months_plus_onboarding_title'),
  'tt8 构建 SixMonthsPlus 弹窗');
check(q31.includes('6 months of Plus, on us') && q31.includes('eligible promo subscription'),
  'q31 内部工具注明促销订阅资格');

// --- Harmony 侧：两键均缺席 ---
const walk = (dir) => readdirSync(dir, { withFileTypes: true })
  .flatMap((e) => e.isDirectory() ? walk(`${dir}/${e.name}`) :
    e.name.endsWith('.ets') ? [`${dir}/${e.name}`] : []);
for (const f of walk('note/src/main/ets')) {
  check(!/notes_role|notesRole|sixMonths|rolePrompt/i.test(read(f)),
    `${f.split('/').pop()} 无角色提示/六个月促销实现`);
}
const harmonyStrings = read('note/src/main/resources/base/element/string.json');
check(!harmonyStrings.includes('notes_role'), 'Harmony 无 notes_role 字符串');
check(!harmonyStrings.includes('six_months_plus'), 'Harmony 无 six_months_plus 字符串');
check(!read('note/src/main/ets/data/OnboardingTooltipStore.ets')
  .includes('sixMonths'), 'OnboardingTooltipStore 不含六个月键');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0661-original-onboarding-sibling-keys-failclosed.md')
  .includes('defaultNotesRolePromptSeen'), 'ADR-0661 声明角色提示边界');
check(read('docs/migration/evidence/original-onboarding-sibling-keys-jadx-2026-09-26.md')
  .includes('eligible promo subscription'), '证据文档记录订阅资格');

console.log(`D05_ORIGINAL_ONBOARDING_SIBLING_KEYS_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
