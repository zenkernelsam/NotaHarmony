// D05 原版「YouTube Transcription」联网转录导入 fail-closed 登记 — Phase 700
// 证据：docs/migration/evidence/original-youtube-transcript-jadx-2026-09-24.md
// 原版 youtube_transcription 是工具行旗标项（ac4.O0=
// NOTE_YOUTUBE_TRANSCRIPTION）：vdg/tzi 对话框（URL 输入 + img.youtube
// 缩略图 + Import）→ ege 以 dqb.I 正则提取 videoId（invalid_url 内联
// 错误）→ re0 协程：rdg 经 youtube oembed 取标题改名笔记（id7.q），
// j55 Apollo GraphQL GetYoutubeTranscript 经私有后端取分段 → cz0.TEXT
// 元素链。核心转录依赖原版私有 GraphQL 后端，Harmony 登记结构性
// fail-closed（等价旗标关闭态）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

const x90 = read(`${SRC}/defpackage/x90.java`);
const ac4 = read(`${SRC}/defpackage/ac4.java`);
const ke1 = read(`${SRC}/defpackage/ke1.java`);
const n32 = read(`${SRC}/defpackage/n32.java`);
const tzi = read(`${SRC}/defpackage/tzi.java`);
const tdg = read(`${SRC}/defpackage/tdg.java`);
const vdg = read(`${SRC}/defpackage/vdg.java`);
const ege = read(`${SRC}/defpackage/ege.java`);
const dqb = read(`${SRC}/defpackage/dqb.java`);
const rdg = read(`${SRC}/defpackage/rdg.java`);
const j55 = read(`${SRC}/defpackage/j55.java`);
const udg = read(`${SRC}/defpackage/udg.java`);
const pw8 = read(`${SRC}/defpackage/pw8.java`);
const cz0 = read(`${SRC}/defpackage/cz0.java`);

const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const strBase = read('note/src/main/resources/base/element/string.json');
const strZh = read('note/src/main/resources/zh_CN/element/string.json');

// --- 原版：旗标门控的工具行条目 ---
check(ac4.includes('"NOTE_YOUTUBE_TRANSCRIPTION", 57'),
  'ac4.O0 is the NOTE_YOUTUBE_TRANSCRIPTION feature flag (index 57)');
check(x90.includes('lc4.a(ac4.O0)') && x90.includes('cq.c'),
  'x90 renders the transcription row only behind ac4.O0');
check(ke1.includes('feature_note__youtube') &&
  ke1.includes('feature_note__youtube_transcription'),
  'ke1(16) is the youtube icon + transcription label row');

// --- 原版：对话框（URL + 缩略图 + Import） ---
check(tzi.includes('feature_note__youtube_link_title') &&
  tzi.includes('img.youtube.com/vi/') && tzi.includes('hqdefault.jpg'),
  'tzi dialog shows link title + img.youtube.com hqdefault preview');
check(n32.includes('feature_note__youtube_import'),
  'n32(3)/xai.b renders the youtube_import button');
check(tdg.includes('boolean') && vdg.includes('bsd.a(new tdg())'),
  'vdg holds tdg dialog state (busy/videoId/errorRes)');

// --- 原版：URL 校验与错误路径 ---
check(dqb.includes('Pattern.compile') && dqb.includes('youtu\\\\.be') &&
  dqb.includes('{11}'),
  'dqb.I is the youtube/watch+youtu.be video-id regex (11-char id)');
check(ege.includes('feature_note__youtube_invalid_url'),
  'ege reports youtube_invalid_url on regex/videoId failure');

// --- 原版：oembed 标题 + GraphQL 转录 + TEXT 物化 ---
check(rdg.includes('www.youtube.com/oembed') && rdg.includes('format=json'),
  'rdg fetches the video title via the youtube oembed endpoint');
check(j55.includes('query GetYoutubeTranscript') &&
  j55.includes('getYoutubeTranscript') && j55.includes('preferredLanguages') &&
  j55.includes('segments'),
  'j55 is the Apollo GetYoutubeTranscript query (private backend)');
check(udg.includes('Failed to rename note') && udg.includes('rdgVar'),
  'udg renames the note to the fetched video title (id7.q)');
check(pw8.includes('getWebViewYouTubePlayer'),
  'pw8 hosts the WebView YouTube player surface');
check(cz0.includes('TEXT') && cz0.includes('IMAGE') && cz0.includes('MATH') &&
  !cz0.includes('VIDEO'),
  'cz0 element set is TEXT/IMAGE/MATH — transcript lands as TEXT elements');

// --- Harmony：无 YouTube 表面（结构性 fail-closed，等价旗标关闭） ---
check(!/youtube|youtu\.be/i.test(toolbar) &&
  !/youtube|youtu\.be/i.test(canvas) &&
  !/youtube|youtu\.be/i.test(page),
  'Harmony editor surfaces carry no youtube integration');
check(!/youtube/i.test(strBase) && !/youtube/i.test(strZh),
  'Harmony string tables have no youtube entries');

console.log(`D05_ORIGINAL_YOUTUBE_TRANSCRIPT_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
