// Phase 731 — MainActivity 属性级审计收口（文档级）
// 证据：adjustNothing/configChanges/singleInstancePerTask/showWhenLocked
//   逐项归属 + 深链矩阵（/app/note 移植、/authlink+/event/* 边界）。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

// === 在位等价项 ===
const mod = read('note/src/main/module.json5');
check('NoteAbility exported', /"exported": true/.test(mod));
check('home skill', /ohos\.want\.action\.home/.test(mod));
check('pdf viewData/sendData skills',
  /ohos\.want\.action\.viewData/.test(mod) &&
  /ohos\.want\.action\.sendData/.test(mod));
check('notability.com 深链声明', /notability\.com/.test(mod));
check('/app/note pathStartWith', /app\/note/.test(mod));

const ability = read('note/src/main/ets/noteability/NoteAbility.ets');
check('onConfigurationUpdate 承载深色切换',
  /onConfigurationUpdate[\s\S]*?COLOR_MODE_DARK/.test(ability));
check('onNewWant 入队等价（单窗口路由）',
  /onNewWant[\s\S]*?enqueue/.test(ability));
check('DeepLinkIngress 消费', /enqueueDeepLinkWant/.test(ability));

const ingress = read('note/src/main/ets/data/DeepLinkIngress.ets');
check('/app/note 段校验（py2.d 等价）', /app\/note|pathSegments|segment/i.test(ingress));
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
check('resolveDeepLinkNoteId（py2.b 等价）', /resolveDeepLinkNoteId/.test(repo));

// === 文档 ===
const adr = read('docs/migration/adr/ADR-0679-original-manifest-activity-attrs.md');
check('ADR-0679 存在', adr.length > 500);
check('ADR 覆盖 adjustNothing→OFFSET 差异', /adjustNothing|KeyboardAvoidMode/.test(adr));
check('ADR 覆盖 singleInstancePerTask 差异', /singleInstancePerTask|singleton/.test(adr));
check('ADR 覆盖锁屏速写边界', /showWhenLocked|turnScreenOn|LAUNCH_CAPTURE/.test(adr));
check('ADR 覆盖 configChanges 等价', /configChanges|onConfigurationUpdate/.test(adr));
check('ADR 覆盖 authlink/event 边界', /authlink|learn-from-home/.test(adr));
check('ADR 覆盖 sendMultipleData 增强登记', /sendMultipleData|SEND_MULTIPLE/.test(adr));

const ev = read('docs/migration/evidence/original-manifest-activity-attrs-jadx-2026-09-25.md');
check('证据文档存在', ev.length > 400);
check('证据含属性逐项表', /adjustNothing|configChanges/.test(ev));
check('证据含深链表', /\/app\/note|authlink/.test(ev));

const report = read('docs/migration/reports/phase-731-original-manifest-activity-attrs.md');
check('中文报告存在', report.length > 400);
check('报告引用原版证据', /adjustNothing|MainActivity/.test(report));

console.log(`D02_ORIGINAL_MANIFEST_ACTIVITY_ATTRS_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
