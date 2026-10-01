// Phase 1411 — Document Defaults 自动笔记标题（o8b 三联偏好 + mcn.g 格式化 +
// a96 Example 预览 + k59.l fallback），decompiled_1.4.2 证据。
//
// 原版证据（decompiled_1.4.2）：
//   o8b.java   DataStore「noteEditorSettings」：KEYS defaultNoteTitle /
//              includeDatePosition / includeTimePosition / undoRedoTapsEnabled；
//              键缺失→null/默认（date=SUFFIX，time=NONE）。
//   hmi.java   hmi 枚举 NONE("None")/PREFIX("Prefix")/SUFFIX("Suffix")，
//              序列化存 name。
//   mcn.java   g(base, datePos, timePos, epochMs)：前缀分量在前、后缀在后、
//              空分量跳过、单空格 join——date=本地化 MEDIUM，time=SHORT。
//   k59.java   l()：custom==null→"Note"（ui_notedefaults fallback）；
//              结果 blank→"..."。
//   yob.java   note_title 子屏 case0/1/default = 字段 / include_date /
//              include_time 行；字段非空尾部 xmark_circle_fill 清除钮。
//   ibb.java   三态位置选择器（None/Prefix/Suffix 下拉），尾部显示当前标签。
//   a96.java   "Example:" + mcn.g(草稿字段值, 位置, remember{now})——预览
//              不套用 title fallback。
//   j8b/zf3/e8b 设置目录 document_defaults→note_title 入口（c1 case2）。
// Harmony：EditorSettingsStore 同键持久化；OriginalNoteTitlePolicy 常驻
//   hmi 常量 + formatOriginalAutoNoteTitle(dateStyle:'medium'/
//   timeStyle:'short' Intl)；LibraryViewModel.createNote 走注入的
//   titleFactory(Date.now())，失败 fail-closed→"New Note"；
//   SettingsPage Document Defaults 区 = 字段(200 上限+清除×) +
//   include_date/time 三态行 + Example 预览 + TitlePositionDialog。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/EditorSettingsStore.ets', 'utf8');
const policy = readFileSync('note/src/main/ets/core/model/OriginalNoteTitlePolicy.ets', 'utf8');
const vm = readFileSync('note/src/main/ets/ui/library/LibraryViewModel.ets', 'utf8');
const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const baseStr = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStr = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

// ── 反编译证据锁定（o8b/mcn/k59/a96/ibb/je）──
const root = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/';
const o8b = readFileSync(`${root}sources/defpackage/o8b.java`, 'utf8');
const mcn = readFileSync(`${root}sources/defpackage/mcn.java`, 'utf8');
const k59 = readFileSync(`${root}sources/defpackage/k59.java`, 'utf8');
const a96 = readFileSync(`${root}sources/defpackage/a96.java`, 'utf8');
const je = readFileSync(`${root}sources/defpackage/je.java`, 'utf8');
const tgh = readFileSync(`${root}sources/defpackage/tgh.java`, 'utf8');
const zq = readFileSync(`${root}sources/defpackage/zq.java`, 'utf8');
const h35 = readFileSync(`${root}sources/defpackage/h35.java`, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

check(o8b.includes('"defaultNoteTitle"'), 'o8b defaultNoteTitle 键');
check(o8b.includes('"includeDatePosition"'), 'o8b includeDatePosition 键');
check(o8b.includes('"includeTimePosition"'), 'o8b includeTimePosition 键');
check(o8b.includes('"undoRedoTapsEnabled"'), 'o8b undoRedoTapsEnabled 键（同 store 既有键）');
check(/static final hmi v\(\)SUFFIX|hmi\.b|SUFFIX;/.test(o8b), 'o8b date 缺省=SUFFIX');
check(o8b.includes('noteEditorSettings'), 'o8b store 名 noteEditorSettings');
check(/static Object f\(o8b[\s\S]*?mcn\.g\(/.test(o8b), 'o8b.f→mcn.g 组装链');
check(/String str2 = j8bVar\.z;[\s\S]*?if \(str2 != null\)[\s\S]*?str = str2/.test(o8b),
  'o8b.f：custom 非 null（含空串）覆盖 fallback');
check(tgh.includes('ofLocalizedDate(FormatStyle.MEDIUM)'),
  'zq.d/tgh(10)=日期 MEDIUM');
check(tgh.includes('ofLocalizedTime(FormatStyle.SHORT)'),
  'zq.e/tgh(11)=时间 SHORT');
check(/tj d = new tj\(new tgh\(10\)\)/.test(zq) && /tj e = new tj\(new tgh\(11\)\)/.test(zq),
  'zq.d=日期、zq.e=时间 formatter 绑定');
check(mcn.includes('zq.M(j)') && mcn.includes('Instant.ofEpochMilli(j)'),
  'mcn.g 用 zq.M/zq.e 取本地化串');
check(k59.includes('ui_notedefaults__default_note_title_fallback'), 'k59 fallback→Note');
check(k59.includes('"...'), 'k59 全空→"..."');
check(/h45\.b\(h35\.R0\)/.test(k59), 'k59.l 经 R0 旗标门控');
check(/new h35\("DOCUMENT_DEFAULT_SETTINGS", 65, qd5Var/.test(h35),
  'R0=DOCUMENT_DEFAULT_SETTINGS（qd5 调试旗标）——Harmony 无条件开放，见 ADR');
check(/feature_settings__example/.test(a96), 'a96 Example: 标签');
check(/200/.test(je), 'je 草稿 ≤200 码元');

// ── EditorSettingsStore：同键持久化 + 缺省/非法回退 ──
check(store.includes("'defaultNoteTitle'"), 'store defaultNoteTitle 键');
check(store.includes("'includeDatePosition'"), 'store includeDatePosition 键');
check(store.includes("'includeTimePosition'"), 'store includeTimePosition 键');
check(/getDefaultNoteTitle[\s\S]*?string \| null/.test(store),
  'getDefaultNoteTitle 缺键→null（保既有注记语义）');
check(store.includes('getIncludeDatePosition'), 'getIncludeDatePosition');
check(store.includes('getIncludeTimePosition'), 'getIncludeTimePosition');
check(/DEFAULT_INCLUDE_DATE_POSITION\s*=\s*NOTE_TITLE_POSITION_SUFFIX|includeDatePosition[\s\S]*?SUFFIX/.test(store),
  'date 缺省=Suffix（o8b v()SUFFIX）');
check(/DEFAULT_INCLUDE_TIME_POSITION\s*=\s*NOTE_TITLE_POSITION_NONE|includeTimePosition[\s\S]*?NONE/.test(store),
  'time 缺省=None');
check(store.includes('sanitizeTitlePosition'), '非法 position→回退缺省（fail-closed）');
check(store.includes('saveDefaultNoteTitle'), 'saveDefaultNoteTitle');
check(store.includes('saveIncludeDatePosition'), 'saveIncludeDatePosition');
check(store.includes('saveIncludeTimePosition'), 'saveIncludeTimePosition');

// ── 策略层：hmi 常量 + mcn.g 格式化等价 ──
check(policy.includes("NOTE_TITLE_POSITION_NONE"), 'hmi NONE 常量');
check(policy.includes('NOTE_TITLE_POSITION_PREFIX'), 'hmi PREFIX 常量');
check(policy.includes('NOTE_TITLE_POSITION_SUFFIX'), 'hmi SUFFIX 常量');
check(policy.includes("'None'") && policy.includes("'Prefix'") && policy.includes("'Suffix'"),
  'position 存英文名（hmi.name 序列化等价）');
check(policy.includes('formatOriginalAutoNoteTitle'), 'mcn.g 等价函数');
check(/dateStyle:\s*'medium'/.test(policy), 'Intl dateStyle medium（mcn MEDIUM 日期）');
check(/timeStyle:\s*'short'/.test(policy), 'Intl timeStyle short（mcn SHORT 时间）');
check(/ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK: string = '\.\.\.'/.test(policy),
  '全空→"..."（k59 等价）');
// mcn.g 组装顺序：前缀在前、基题在中、后缀在后、空分量跳过
check(/prefixParts|push\(.*date|prefix/.test(policy), 'mcn.g 前缀分量组装');
check(/join\(' '\)/.test(policy), '单空格 join（mcn.g）');

// ── LibraryViewModel：createNote 走 titleFactory + fail-closed ──
check(/noteTitleFactory/.test(vm), 'VM 持有 titleFactory');
check(/await this\.noteTitleFactory\(Date\.now\(\)\)/.test(vm),
  'createNote 调用 factory(Date.now())');
check(/title\s*=\s*ORIGINAL_NOTE_DEFAULT_TITLE[\s\S]*?catch/.test(vm) ||
  /catch[\s\S]*?ORIGINAL_NOTE_DEFAULT_TITLE/.test(vm),
  'factory 失败→"New Note" fail-closed');
check(/createNote\(title/.test(vm), 'createNote 用 factory 结果');

// ── LibraryPage：factory 装配 + fallback 链 ──
check(lib.includes('formatOriginalAutoNoteTitle'), '页面引用 mcn.g 等价');
check(lib.includes('getDefaultNoteTitle'), '页面读 defaultNoteTitle');
check(lib.includes('getIncludeDatePosition'), '页面读 date position');
check(lib.includes('getIncludeTimePosition'), '页面读 time position');
check(lib.includes('default_note_title_fallback'), '页面用 ui_notedefaults "Note" fallback');
check(lib.includes('ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK'), '页面 "..." 兜底');

// ── SettingsPage：Document Defaults 区 ──
check(settings.includes('document_defaults'), 'Document defaults 区');
check(settings.includes('default_note_title'), 'default note title 字段');
check(settings.includes('default_note_title_fallback'), '字段占位=Note');
check(settings.includes('include_date'), 'include_date 行');
check(settings.includes('include_time'), 'include_time 行');
check(settings.includes('example_label'), 'Example: 预览');
check(settings.includes('TitlePositionDialog'), '三态位置 dialog');
check(/\.maxLength\(200\)/.test(settings), '字段 200 码元上限（je case11）');
check(settings.includes('close_med_regular'), '清除钮 close glyph（xmark_circle_fill 等价）');
check(settings.includes('clear_field'), '清除钮 cd');
check(/this\.includeDateDialog\.open\(\)/.test(settings), 'date 行开 dialog');
check(/this\.includeTimeDialog\.open\(\)/.test(settings), 'time 行开 dialog');
check(settings.includes('setDefaultNoteTitle'), '字段写入 setter');
check(settings.includes('setIncludeDatePosition'), 'date setter');
check(settings.includes('setIncludeTimePosition'), 'time setter');
check(settings.includes('noteTitleExample'), 'Example 实时预览（a96 等价）');
// 行尾标签 = 当前位置（ibb 尾部显示）
check(/titlePositionLabel\(this\.includeDatePosition\)/.test(settings), 'date 行尾当前标签');
check(/titlePositionLabel\(this\.includeTimePosition\)/.test(settings), 'time 行尾当前标签');

// ── 字符串资源：en + zh ──
for (const [key, en, zh] of [
  ['document_defaults', 'Document defaults', '文稿默认值'],
  ['note_title', 'Note title', '笔记标题'],
  ['default_note_title', 'Default note title', '默认笔记标题'],
  ['default_note_title_fallback', 'Note', '笔记'],
  ['include_date', 'Include date', '包含日期'],
  ['include_time', 'Include time', '包含时间'],
  ['title_position_none', 'None', '无'],
  ['title_position_prefix', 'Prefix', '前缀'],
  ['title_position_suffix', 'Suffix', '后缀'],
  ['example_label', 'Example:', '示例：'],
  ['clear_field', 'Clear', '清除'],
]) {
  check(baseStr.includes(`"name": "${key}"`), `base 串 ${key}`);
  check(baseStr.includes(en), `base 串 ${key} 文案`);
  check(zhStr.includes(`"name": "${key}"`), `zh 串 ${key}`);
  check(zhStr.includes(zh), `zh 串 ${key} 文案`);
}

console.log(`PASS auto-note-title (${n} checks)`);
