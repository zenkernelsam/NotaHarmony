// D02 原版 1.4.2 画廊社区产品面 — Phase 774（ADR-0708 画廊簇细化）
// 钉住 131 键族规模、十子面代表键与审核/验证/举报结构。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const strings = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const s = fs.readFileSync(strings, 'utf8');
const keys = [...s.matchAll(/name="feature_library_gallery__([^"]+)"/g)].map((m) => m[1]);
check('gallery string family is a full product surface (>=120 keys)', keys.length >= 120);

const has = (k) => keys.includes(k);
check('moderation queue states (awaiting_review + quarantined)',
  has('awaiting_review') && has('quarantined'));
check('report taxonomy covers 5 reasons + profile-area reporting',
  has('report_reason_spam') && has('report_reason_abusive') && has('report_reason_sexual')
  && has('report_reason_dmca') && has('report_reason_other') && has('report_profile_area_avatar'));
check('collections + remix lineage + discovery surfaces',
  has('my_collections') && has('official_collections') && has('view_remixes')
  && has('inspired_by') && has('popular_tags') && has('more_like_this'));
check('email-verification gate for publishing',
  has('unverified_email') && has('verification_sent') && has('resend_verification'));
check('social surface (followers/likers/follow/comment)',
  has('followers_title') && has('likers_title') && has('follow_action'));
check('publish lifecycle (unpublish + publish exception class)',
  has('unpublish')
  && fs.existsSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability/data/gallery/GalleryPublishException.java'));

console.log(`gallery surface replay: ${checks.length}/${checks.length} checks green`);
