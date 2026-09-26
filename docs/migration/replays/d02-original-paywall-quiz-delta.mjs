// D02 原版 1.4.2 售卖页+测验讲题/计分面 — Phase 788
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('note_limit_offer paywall sheet: trigger/plan/CTA/dismiss set',
  ['reached', 'unlock_heading', 'plan_name', 'cta_upgrade',
    'see_all_plans', 'not_now', 'cd_close', 'badge', 'intro_terms',
    'bare_terms', 'reassurance',
    'feature_audio_quizzes', 'feature_handwriting_search']
    .every((k) => s142.includes(`note_limit_offer_${k}">`))
  && s142.includes('feature_paywall__restore_subscribed_elsewhere">'));
check('paywall family absent in 1.0.3',
  !s103.includes('note_limit_offer'));
check('quiz explain-chat bridge (explain_this/prompts/headings/continue)',
  ['explain_this', 'explain_prompt_expand', 'explain_prompt_topics',
    'explain_prompt_tutor', 'explain_generating',
    'explain_chat_heading_answer', 'explain_chat_heading_explanation',
    'explain_chat_heading_question', 'explain_chat_heading_request',
    'explain_continue_with_chat']
    .every((k) => s142.includes(`feature_learn_quiz__${k}">`)));
check('quiz scoring feedback labels + caught-up session-end keys',
  ['correct', 'incorrect', 'skipped', 'your_answer', 'open_note',
    'caught_up_header', 'caught_up_body', 'caught_up_continue_to_quiz',
    'caught_up_exit_session']
    .every((k) => s142.includes(`feature_learn_quiz__${k}">`)));
check('explain/caught-up families absent in 1.0.3',
  !s103.includes('explain_this') && !s103.includes('caught_up_header'));

console.log(`paywall/quiz delta replay: ${checks.length}/${checks.length} checks green`);
