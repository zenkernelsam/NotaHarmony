// Phase 1417 — 原版设置页 About 区（Blog 钮 + Discord 卡 + 社交图标行）移植
// 证据链：xpa About 区 → yrm.a(title=feature_settings__about, v0(1))；
// v0 case1 → wxm.a(k1 VM) → ec2.e(items=s0)；s0 case0 尾部 =
// w8n.b 钮卡[rate(flag)/blog/flag 项] + aq8.j0[wxm.b Discord 卡, wxm.c 社交行]；
// wxm.b = tee.a 16dp 卡 + u0(3)（discord_title/description + x6n.a×2 → t0(2)/(3)）；
// wxm.c = cc3.l×5（cd_* + t0(5/6/7/8/0)）；t0→j1→URL（j1 case 0-8）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const REPO = 'C:/HarmonyProject/NotaHarmony';
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const S = `${JADX}/sources/defpackage`;

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = (p) => fs.readFileSync(p, 'utf8');

// ── 原版钉 ──
const xpa = read(`${S}/xpa.java`);
check('xpa：About 区标题行 yrm.a(feature_settings__about, v0(1))',
  xpa.includes('R.string.feature_settings__about') &&
  xpa.includes('new v0(bz5Var10, (byte) 1)'));

const v0 = read(`${S}/v0.java`);
check('v0 case1 → wxm.a(bz5)（About 内容宿主）',
  /case 1:[\s\S]*?wxm\.a\(bz5Var/.test(v0));

const wxm = read(`${S}/wxm.java`);
check('wxm.a：k1 VM + ec2.e(s0)（About 区 = 内嵌项列表）',
  wxm.includes('ec2.e') && wxm.includes('new s0(k1Var, bz5Var, b)'));
check('wxm.b：Discord 卡 = tee.a 16dp + u0(k1,3) 内容',
  wxm.includes('tee.a(hx7.K(w8aVarF, 16.0f)') &&
  wxm.includes('new u0(k1Var, (byte) 3)'));
check('wxm.c：五枚 cc3.l 图标钮 + cd_* 语义 + t0(5/6/7/8/0) 分发',
  wxm.includes('R.drawable.feature_settings__instagram') &&
  wxm.includes('R.drawable.ui_designsystem__youtube') &&
  wxm.includes('R.drawable.feature_settings__tiktok') &&
  wxm.includes('R.drawable.feature_settings__threads') &&
  wxm.includes('R.drawable.feature_settings__linkedin') &&
  wxm.includes('feature_settings__cd_instagram') &&
  wxm.includes('feature_settings__cd_youtube') &&
  wxm.includes('feature_settings__cd_tiktok') &&
  wxm.includes('feature_settings__cd_threads') &&
  wxm.includes('feature_settings__cd_linkedin') &&
  wxm.includes('new t0(k1Var, (byte) 5)') &&
  wxm.includes('new t0(k1Var, (byte) 6)') &&
  wxm.includes('new t0(k1Var, (byte) 7)') &&
  wxm.includes('new t0(k1Var, (byte) 8)'));

const u0 = read(`${S}/u0.java`);
check('u0 case3：discord_title(z5i.I)+description(z5i.J)+x6n.a×2(t0(2)/t0(3))',
  u0.includes('R.string.feature_settings__discord_title') &&
  u0.includes('R.string.feature_settings__discord_description') &&
  u0.includes('new t0(k1Var, (byte) 2)') &&
  u0.includes('new t0(k1Var, (byte) 3)') &&
  (u0.match(/x6n\.a\(/g) ?? []).length >= 2 &&
  u0.includes('ubl.g') && u0.includes('ubl.h'));

const s0 = read(`${S}/s0.java`);
check('s0：尾部 aq8.j0 追加 wxm.b(Discord 卡) + wxm.c(社交行)',
  s0.includes('wxm.b(k1Var2, nc6Var, 8)') && s0.includes('wxm.c(k1Var2, nc6Var2, 8)'));

const j1 = read(`${S}/j1.java`);
check('j1 URL 映射：blog/discord/support/instagram/linkedin/playstore/threads/tiktok/youtube',
  j1.includes('https://blog.notability.com') &&
  j1.includes('https://discord.gg/Fw9SsRYU7a') &&
  j1.includes('support.gingerlabs.com/hc/en-us/articles/5459034545178') &&
  j1.includes('instagram.com/notabilityapp') &&
  j1.includes('linkedin.com/company/ginger-labs') &&
  j1.includes('play.google.com/store/apps/details?id=com.gingerlabs.notability') &&
  j1.includes('threads.com/@notabilityapp') &&
  j1.includes('tiktok.com/@notabilityapp') &&
  j1.includes('youtube.com/notability'));

const t0 = read(`${S}/t0.java`);
check('t0 case 分发：5→j1(b2=3)instagram / 6→j1(8)youtube / 7→j1(7)tiktok / 8→j1(6)threads / 0→j1(4)linkedin',
  t0.includes('byte b2 = 3') &&
  /case 5:[\s\S]*?new j1\(k1Var, ps2Var, b2\)/.test(t0) &&
  /case 6:[\s\S]*?new j1\(k1Var, ps2Var, \(byte\) 8\)/.test(t0) &&
  /case 7:[\s\S]*?new j1\(k1Var, ps2Var, \(byte\) 7\)/.test(t0) &&
  /default:[\s\S]*?new j1\(k1Var, ps2Var, \(byte\) 6\)/.test(t0) &&
  /case 0:[\s\S]*?new j1\(k1Var, ps2Var, \(byte\) 4\)/.test(t0));

const stringsXml = read(`${JADX}/resources/res/values/strings.xml`);
check('原版文案：about/blog/discord 四条 + 五条 cd_*',
  stringsXml.includes('<string name="feature_settings__about">About</string>') &&
  stringsXml.includes('<string name="feature_settings__blog">Blog</string>') &&
  stringsXml.includes('discord_title">Join us on Discord!</string>') &&
  stringsXml.includes('discord_description">Share feedback and ideas directly with the team in safe space.</string>') &&
  stringsXml.includes('discord_accept_invite">Accept invite</string>') &&
  stringsXml.includes('discord_learn_more">Learn more</string>') &&
  stringsXml.includes('cd_instagram">Open Notability on Instagram</string>') &&
  stringsXml.includes('cd_linkedin">Open Notability on LinkedIn</string>') &&
  stringsXml.includes('cd_threads">Open Notability on Threads</string>') &&
  stringsXml.includes('cd_tiktok">Open Notability on TikTok</string>') &&
  stringsXml.includes('cd_youtube">Open Notability on YouTube</string>'));

// ── Harmony 钉 ──
const page = read(`${REPO}/note/src/main/ets/ui/settings/SettingsPage.ets`);
check('SettingsPage：About 区标题 + Blog 钮 + Discord 卡 + 社交行全部存在',
  page.includes(`$r('app.string.feature_settings__about')`) &&
  page.includes(`$r('app.string.feature_settings__blog')`) &&
  page.includes(`$r('app.string.feature_settings__discord_title')`) &&
  page.includes(`$r('app.string.feature_settings__discord_description')`) &&
  page.includes(`$r('app.string.feature_settings__discord_accept_invite')`) &&
  page.includes(`$r('app.string.feature_settings__discord_learn_more')`));

check('About 区位于 backup_and_sync 之后（原版 About 区在设置尾部）',
  page.indexOf(`$r('app.string.backup_and_sync')`) <
  page.indexOf(`$r('app.string.feature_settings__about')`));

check('openExternalLink：getContext + context.openLink + catch（k1.z→startActivity 等价）',
  /openExternalLink\(url: string\)[\s\S]*?context\.openLink\(url\)\.catch/.test(page));

check('五条 j1 可移植 URL 逐字（blog/discord/support + 五社交域）',
  page.includes(`'https://blog.notability.com'`) &&
  page.includes(`'https://discord.gg/Fw9SsRYU7a'`) &&
  page.includes(`'https://support.gingerlabs.com/hc/en-us/articles/5459034545178-Join-the-Notability-Discord-Server'`) &&
  page.includes(`'https://www.instagram.com/notabilityapp'`) &&
  page.includes(`'https://youtube.com/notability'`) &&
  page.includes(`'https://www.tiktok.com/@notabilityapp'`) &&
  page.includes(`'https://www.threads.com/@notabilityapp'`) &&
  page.includes(`'https://www.linkedin.com/company/ginger-labs'`));

check('社交行 = ForEach(socialLinks) 顺序 instagram→youtube→tiktok→threads→linkedin + cd_* a11y',
  page.includes('ForEach(this.socialLinks') &&
  page.indexOf(`glyph: 'instagram'`) < page.indexOf(`glyph: 'youtube'`) &&
  page.indexOf(`glyph: 'youtube'`) < page.indexOf(`glyph: 'tiktok'`) &&
  page.indexOf(`glyph: 'tiktok'`) < page.indexOf(`glyph: 'threads'`) &&
  page.indexOf(`glyph: 'threads'`) < page.indexOf(`glyph: 'linkedin'`) &&
  page.includes('feature_settings__cd_instagram') &&
  page.includes('feature_settings__cd_linkedin'));

check('Discord 卡：accent 主钮(Accept invite) + control 次钮(Learn more)',
  /discord_accept_invite[\s\S]*?backgroundColor\(this\.resolveTokens\(\)\.accent\)[\s\S]*?discord_learn_more[\s\S]*?backgroundColor\(this\.resolveTokens\(\)\.control\)/.test(page));

const glyphs = read(`${REPO}/note/src/main/ets/ui/components/ToolGlyphs.ets`);
check('ToolGlyphs：instagram/youtube/tiktok/threads/linkedin 五枚 24×24 fill',
  /'instagram': \{ f: `M11\.995,9\.704/.test(glyphs) &&
  /'youtube': \{ f: `M10\.429,14\.28/.test(glyphs) &&
  /'tiktok': \{ f: `M12,0C5\.373/.test(glyphs) &&
  /'threads': \{ f: `M11\.793,12\.278/.test(glyphs) &&
  /'linkedin': \{ f: `M0,12C0,5\.373/.test(glyphs));

const enJson = read(`${REPO}/note/src/main/resources/base/element/string.json`);
const zhJson = read(`${REPO}/note/src/main/resources/zh_CN/element/string.json`);
check('string.json en：feature_settings__about/blog/discord×4/cd×5 全键',
  enJson.includes('"feature_settings__about"') && enJson.includes('"feature_settings__blog"') &&
  enJson.includes('"feature_settings__discord_title"') &&
  enJson.includes('"feature_settings__discord_description"') &&
  enJson.includes('"feature_settings__discord_accept_invite"') &&
  enJson.includes('"feature_settings__discord_learn_more"') &&
  enJson.includes('"feature_settings__cd_instagram"') &&
  enJson.includes('"feature_settings__cd_linkedin"') &&
  enJson.includes('"feature_settings__cd_threads"') &&
  enJson.includes('"feature_settings__cd_tiktok"') &&
  enJson.includes('"feature_settings__cd_youtube"'));
check('string.json zh：同键中文翻译',
  zhJson.includes('"feature_settings__about"') &&
  zhJson.includes('"feature_settings__discord_title"') &&
  zhJson.includes('"feature_settings__cd_instagram"') &&
  zhJson.includes('加入我们的 Discord'));

// ── fail-closed 钉 ──
const pageCode = page.split('\n').filter((l) => !l.trimStart().startsWith('//')).join('\n');
check('rate_notability（play.google.com）fail-closed：非注释代码无 Play Store 引用',
  !pageCode.includes('play.google.com') && !enJson.includes('rate_notability'));
check('h35.Y0 flag 项（Newsletter 等）未伪造宿主',
  !enJson.includes('feature_settings__newsletter'));

console.log(`\n${checks.length} checks passed`);
