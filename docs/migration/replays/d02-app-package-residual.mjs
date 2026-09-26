// Phase 836 — app/ 包残余面（initializers + widget config 基类）
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability/app';
const logging = readFileSync(join(S, 'initializers/LoggingInitializer.java'), 'utf8');
const appStartup = readFileSync(join(S, 'initializers/AppStartupInitializer.java'), 'utf8');
const folderCfg = readFileSync(join(S, 'widgets/FolderNotesConfigActivity.java'), 'utf8');
const thumbCfg = readFileSync(join(S, 'widgets/NoteThumbnailConfigActivity.java'), 'utf8');
const a2k = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/a2k.java', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// Initializer 链
ck('LoggingInitializer implements rm7', logging.includes('rm7'));
ck('Logging 依赖 4 DataStore initializer', ['UserDataStoreInitializer', 'ThemeDataStoreInitializer', 'NoteEditorSettingsInitializer', 'HapticPreferencesInitializer'].every(d => logging.includes(d)));
ck('GMS 证书 SecurityException 吞掉', logging.includes('Swallowed Play Services certificate SecurityException'));
ck('UncaughtExceptionHandler 装设', logging.includes('UncaughtExceptionHandler'));
ck('thread.name 日志维度', logging.includes('"thread.name"'));
ck('AppStartup 依赖 LoggingInitializer', appStartup.includes('LoggingInitializer.class'));

// a2k 基类 + 配置 activity
ck('a2k 抽象 h() 返回字符串', a2k.includes('public abstract int h()'));
ck('a2k onCreate finish 门控', /onCreate[\s\S]{0,400}finish\(\)/.test(a2k));
ck('FolderConfig→folder_picker_login_required', folderCfg.includes('widget_folder_picker_login_required'));
ck('ThumbConfig→note_picker_login_required', thumbCfg.includes('widget_note_picker_login_required'));
ck('Thumb picker sheet 字符串面', ['widget_note_thumbnail_picker_title', 'widget_note_picker_search_hint', 'widget_picker_no_notes'].every(s => thumbCfg.includes(s)));

// 版本存续
let both103 = true;
try {
  readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/app/initializers/AppStartupInitializer.java', 'utf8');
  readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/app/initializers/LoggingInitializer.java', 'utf8');
} catch { both103 = false; }
ck('initializer 对 1.0.3 已存在', both103);

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
