// Phase 833 — Receiver/Widget 代码语义
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const recv = readFileSync(join(S, 'com/gingerlabs/notability/app/AppUpgradeReceiver.java'), 'utf8');
const zv = readFileSync(join(S, 'defpackage/zv.java'), 'utf8');
const recent = readFileSync(join(S, 'com/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider.java'), 'utf8');
const img = readFileSync(join(S, 'com/gingerlabs/notability/app/widgets/WidgetImageProvider.java'), 'utf8');
const form = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteformability/NoteFormAbility.ets', 'utf8')
  + readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteformability/pages/FolderNotesCard.ets', 'utf8')
  + readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// AppUpgradeReceiver = baseline-profile 重写
ck('MY_PACKAGE_REPLACED 守卫', recv.includes('MY_PACKAGE_REPLACED'));
ck('goAsync PendingResult', recv.includes('goAsync()'));
ck('AtomicBoolean finish-once', recv.includes('compareAndSet(false, true)') && recv.includes('pendingResult.finish()'));
ck('tid.b profileinstaller 重写', zv.includes('tid.b(context'));
ck('Baseline profile 锁守卫日志', zv.includes('Baseline profile write skipped'));

// Widget provider hng 模型
ck('hng(label,create,view,collection)', recent.includes('new hng(string, action, intentPutExtra, collectionValues)'));
ck('CREATE_NOTE action', recent.includes('"android.intent.action.CREATE_NOTE"'));
ck('show_recent extra 产生点', recent.includes('putExtra("show_recent", true)'));
ck('aub 尺寸接口 c/d/e', recent.includes('public final int c()') && recent.includes('public final int d()'));

// WidgetImageProvider 双路径类
ck('thumbnail 路径类', img.includes('"thumbnail"'));
ck('text 路径类', img.includes('"text"'));
ck('48dp 圆角渲染 kbn.c', img.includes('density * 48.0f') && img.includes('widget_thumb_corner_radius'));
ck('?f= 自定义文件回退', img.includes('getQueryParameter("f")'));
ck('FileNotFoundException fail-closed', img.includes('FileNotFoundException'));

// Harmony 侧
ck('Harmony formProvider 编辑能力', form.includes('openFormEditAbility'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
