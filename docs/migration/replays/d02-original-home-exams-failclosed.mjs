// Phase 1413 — 原版 Home "Upcoming exams" fail-closed 钉件（ADR-1349）
// 证据链：cbl 设备事件恒 l=false；jt1:1589 SYLLABUS 合流(g=="EXAM")；
//         xy5 case1 未来7天(不含今日)过滤+文件夹解析；q8n.e/卡面渲染。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

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

// ── 原版钉：exam 标志只能来自 SYLLABUS ──
const cbl = read(`${S}/cbl.java`);
check('cbl: 设备日历事件恒 DEVICE/k=null/l=false',
  /new ag1\([\s\S]*?zf1\.F, null, false\)/.test(cbl) &&
  !/new ag1\([\s\S]*?zf1\.G/.test(cbl));

const jt1 = read(`${S}/jt1.java`);
check('jt1: SYLLABUS 合流含 g=="EXAM" 判定位',
  jt1.includes('zf1.G') && jt1.includes('zx7.r(lhhVar.g, "EXAM")'));
check('jt1: SYLLABUS 事件携带文件夹引用 k=lhhVar.b',
  jt1.includes('zf1.G, lhhVar.b'));

const fch = read(`${S}/fch.java`);
check('syllabusEvents 为 Room 表（Learn 管道产物）',
  fch.includes('SELECT * FROM syllabusEvents') && fch.includes('syllabusCourses'));

const ih4 = read(`${S}/ih4.java`);
check('ih4: fl2→lhh 转写入库（课表解析写入方）',
  ih4.includes('new lhh(') && ih4.includes('fl2Var'));

const uih = read(`${S}/uih.java`);
check('uih 属 data.learn.syllabus 服务端解析管道',
  uih.includes('SyllabusParseException'));

// ── 原版钉：xy5 case1 过滤窗 + pij 卡模型 ──
const xy5 = read(`${S}/xy5.java`);
check('xy5 case1: exam 过滤 l==true + [tomorrow, today+8d) 窗',
  xy5.includes('ag1Var.l') && xy5.includes('plusDays(1L)') && xy5.includes('plusDays(8L)'));
check('xy5 case1: k→cpj→文件夹解析失败即丢弃',
  xy5.includes('ymm.d(str2)') && xy5.includes('ip5Var.l(cpjVar)') && xy5.includes('pijVar = null'));
check('xy5 case1: 空卡列表不 emit rij',
  xy5.includes('new rij(arrayList6)') && xy5.includes('!arrayList6.isEmpty()'));

const pij = read(`${S}/pij.java`);
check('pij 卡字段 {id,title,daysUntil,date,color,folderTitle,folderId}',
  pij.includes('LocalDate') && pij.includes('cpj') && /String a;|this\.a = str/.test(pij));

// ── 原版钉：q8n 卡面 + vkm 顺序 + Learn Review 按钮 ──
const q8n = read(`${S}/q8n.java`);
check('q8n: 节头 home_upcoming_exams_title',
  q8n.includes('feature_library__home_upcoming_exams_title'));
check('q8n: tomorrow / days_until 倒计时',
  q8n.includes('home_exam_tomorrow') && q8n.includes('home_exam_days_until'));
check('q8n: 文件夹 chip a11y home_exam_open_folder',
  q8n.includes('home_exam_open_folder'));
check('q8n: 空标题回退沿用 coming_up_untitled_event',
  q8n.includes('home_coming_up_untitled_event'));

const ig2 = read(`${S}/ig2.java`);
check('ig2/acm.a: Review 按钮 = aisparkle + home_exam_review（Learn AI 入口）',
  ig2.includes('aisparkle_med_bold') && ig2.includes('home_exam_review'));

const vkm = read(`${S}/vkm.java`);
check('vkm: Coming Up(kan.a) 之后渲染 q8n.e(rijVar!=null 才出现)',
  vkm.includes('kan.a(kb2Var') && vkm.includes('q8n.e(rijVar'));

// ── Harmony 钉：fail-closed 无实现 ──
const lp = read(path.join(REPO, 'note/src/main/ets/ui/library/LibraryPage.ets'));
const stringsEn = JSON.parse(read(path.join(REPO, 'note/src/main/resources/base/element/string.json')));
const allStr = JSON.stringify(stringsEn);
check('Harmony: 无 home_exam_* 字串（无 UI 消费方）',
  !allStr.includes('home_exam') && !allStr.includes('upcoming_exams'));
const lpCode = lp.split('\n').filter(l => !l.trim().startsWith('//')).join('\n');
check('Harmony: LibraryPage 无 Exams 节渲染（仅注释登记缺省）',
  !/exam/i.test(lpCode) && !lpCode.includes('q8n'));
check('Harmony: 无 syllabusEvents/课程文件夹等价实现',
  !fs.existsSync(path.join(REPO, 'note/src/main/ets/data/SyllabusEvents.ets')) &&
  !JSON.stringify(fs.readdirSync(path.join(REPO, 'note/src/main/ets/data'))).toLowerCase().includes('syllabus'));
check('ADR-1349 登记 fail-closed',
  fs.existsSync(path.join(REPO, 'docs/migration/adr/ADR-1349-home-exams-failclosed.md')));
check('证据文档存在',
  fs.existsSync(path.join(REPO, 'docs/migration/evidence/phase-1413-home-exams.md')));

console.log(`\nhome-exams-failclosed replay: ${checks.length}/${checks.length} checks green`);
