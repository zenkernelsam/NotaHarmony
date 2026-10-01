// D02 原版 1.4.2 assets/ 尾部轴收口（Phase 1431 裁决）
// spellcheck/en_words.dat（+LICENSE）：bc1 词典加载（GZIP→150k HashSet，
// BreakIterator 分词，v6n.h 提取 misspell 区段 → cji/ff7 合并进 zle
// 文本布局 → 波浪下划线）。整条链路挂 NOTE_SPELLCHECK=h35.a1 =
// new h35(..., qd5) —— qd5.toString() 直证 "DebugOnly"；wki.C0=
// h45.b(a1) 生产构建恒 false（管线+D0/E0 可见流全断）；设置行
// check_spelling 也只在 axg.java:115 的 !h45.b(a1) ? em4.F 分支外
// 渲染 —— 未发布调试特性，fail-closed 不虚构。
// conf/*.conf + resources/*.res：MyScript iink 引擎配置与资源包
// （diagram/en_US/math2/raw-content2/shape）→ 随 ADR-0645 后端边界
// fail-closed（原生引擎不可移植）。
// mlkit-google-ocr-models/（21 个 tflite/binarypb）：vendored MLKit。
// dexopt/baseline.prof(m)：ART 基线 profile，平台边界。
// ConversionRates.csv：k4f 付费墙币种换算表 → 订阅后端边界。
// PublicSuffixDatabase.list：OkHttp vendored。
// glmath/（73）：MicroTeX 字体/映射 —— 已由 math 渲染链打包移植
// （rawfile/glmath 存在）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const strings = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');
const adr = read('docs/migration/adr/ADR-1366-assets-tail-closure.md');
const ev = read('docs/migration/evidence/phase-1431-assets-tail.md');

// --- 词检链路 fail-closed（DebugOnly + 词典资产不打包） ---
check('no spellcheck dictionary or misspell pipeline in Harmony source',
  !fs.existsSync('note/src/main/resources/rawfile/en_words.dat') &&
  !fs.existsSync('note/src/main/resources/rawfile/spellcheck/en_words.dat'));
check('no check_spelling settings row fabricated',
  !strings.includes('check_spelling') && !stringsZh.includes('check_spelling'));
check('ADR records NOTE_SPELLCHECK=qd5 DebugOnly gate + wki.C0 evidence',
  adr.includes('NOTE_SPELLCHECK') && adr.includes('qd5') &&
  adr.includes('DebugOnly') && adr.includes('wki'));
check('evidence records bc1/v6n.h/cji pipeline and en_words.dat',
  ev.includes('en_words.dat') && ev.includes('v6n.h') &&
  ev.includes('bc1'));

// --- iink / vendored 资产边界登记 ---
check('ADR records iink conf/res + mlkit + dexopt + paywall-csv + okhttp axes',
  adr.includes('diagram.conf') && adr.includes('mlkit-google-ocr-models') &&
  adr.includes('baseline.prof') && adr.includes('ConversionRates.csv') &&
  adr.includes('PublicSuffixDatabase'));

// --- 已打包资产一致性存在性 ---
check('glmath rawfile tree still bundled (math render chain)',
  fs.existsSync('note/src/main/resources/rawfile/glmath'));

console.log(`TOTAL=${checks.length} FAILED=0`);
