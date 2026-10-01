// Phase 1403 — 原版 1.4.2 捆绑模板 Set as default（pth.g → ju8 case26 →
// o8b.x pdfAssetPath；wq3.b → a1d/x0d 默认解析；lk3/h1d.b 建笔记后应用）。
// 原版证据（decompiled_1.4.2）：
//   u7n.e cell 回调 onSetDefaultPaperTemplate(chc) → yia(1,rsh)→vuh→pth.g；
//   od7 case3：t92 下拉菜单中 yl2.f("Set as default") = s86(dismiss +
//     bz5(qgc.b)) —— cell 长按菜单唯一项。
//   ju8 case26：读 pfc(o8b.w) → 新 pfc(wfc, tr0) 回写 + ega.g(o8b.x, chc.e)；
//     g8b case0（程序化 set-default）对称清除 o8b.x。
//   wq3.b：o8b.x 解析出 chc → a1d(chc)；否则 pfc → x0d —— 打包默认胜出。
//   lk3（qp9.O 建笔记流）：h1d.b(cpj, null, null, true) → f1d → sqc.b →
//     应用到首页；此路径不经 pth.t —— 默认应用不写 recents/usage；
//     IOException → a() 日志支路，不回滚已建笔记。
// Harmony 落点：BundledTemplateMetaStore.defaultPaperTemplatePath ↔ o8b.x；
//   cell bindContextMenu(LongPress) 单项 Set as default；
//   applyBundledTemplateDefault（LibraryViewModel 注入）建笔记后改首页
//   background 为 PageBackground.pdf；catalog miss → fail-closed 保留纸型。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const store = readFileSync('note/src/main/ets/data/BundledTemplateMetaStore.ets', 'utf8');
const apply = readFileSync('note/src/main/ets/data/BundledPaperTemplateApply.ets', 'utf8');
const gallery = readFileSync('note/src/main/ets/ui/editor/PaperTemplateGallery.ets', 'utf8');
const vm = readFileSync('note/src/main/ets/ui/library/LibraryViewModel.ets', 'utf8');
const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 默认路径持久化（o8b.x 等价）──
check(/DEFAULT_PATH_KEY: string = 'defaultPaperTemplatePath'/.test(store),
  'o8b.x 等价键');
check(/async getDefaultPath\(\): Promise<string>/.test(store), 'getDefaultPath');
check(/typeof raw === 'string' && raw\.length > 0/.test(store),
  'getDefaultPath 未设/非串 → 空串');
check(/async setDefaultPath\(pdfAssetPath: string\)/.test(store) &&
  /putSync\(DEFAULT_PATH_KEY, pdfAssetPath\)/.test(store) &&
  /flush\(\)/.test(store), 'setDefaultPath put+flush');
check(/async clearDefaultPath\(\)/.test(store) &&
  /deleteSync\(DEFAULT_PATH_KEY\)/.test(store), 'clearDefaultPath（g8b 对称面）');
check(/mutex\.runExclusive/.test(store) &&
  /runExclusive[\s\S]*setDefaultPath|setDefaultPath[\s\S]*runExclusive/.test(store),
  '默认写走互斥');

// ── cell 上下文菜单（od7 case3 t92 等价）──
check(/bindContextMenu\(this\.cellMenu, ResponseType\.LongPress\)/.test(gallery),
  '长按上下文菜单');
check(/MenuItem\(\{ content: \$r\('app\.string\.paper_templates_set_default'\)/.test(gallery),
  'Set as default 菜单项（原版字符串同名）');
check(/onSetDefault: \(\) => void = \(\) =>/.test(gallery), 'cell onSetDefault prop');
check(/onSetDefault: \(\): void =>\s*this\.setDefault\(item\.variant\)/.test(gallery),
  'cell → gallery setDefault(variant)');
check(/private setDefault\(variant: BundledPaperVariant\)/.test(gallery) &&
  /setDefaultPath\(variant\.rawfilePath\)/.test(gallery),
  'pth.g(chc) → o8b.x=chc.e（rawfilePath）');
check(/setDefaultPath\(variant\.rawfilePath\)\.catch/.test(gallery),
  'setDefault 失败仅记日志（原版 coroutine 无 UI 反馈）');

// ── 新建笔记消费端（lk3/h1d.b 等价）──
check(/export async function applyBundledTemplateDefault/.test(apply),
  'applyBundledTemplateDefault');
check(/getDefaultPath\(\)/.test(apply) && /path\.length === 0/.test(apply),
  'o8b.x 未设 → 早退');
check(/findBundledPaperVariantByPath\(path\)/.test(apply) &&
  /match === null/.test(apply), 'catalog miss → fail-closed');
check(/pages\[0\]/.test(apply), '应用到首页（bpj 首页坐标）');
check(/buildBundledTemplatePageBackground\(context, database, noteId,\s*match\.variant\)/.test(apply),
  '复用 sqc.b 等价打包背景构建');
check(/clonePageInfo\(pages\[0\]\)/.test(apply) &&
  /applied\.background = result\.background/.test(apply) &&
  /pageRepo\.updatePage\(applied\)/.test(apply), '首页 background 落库');
check(!/recordUsed|recordUsed\(/.test(apply.slice(apply.indexOf('applyBundledTemplateDefault'),
  apply.indexOf('applyBundledTemplateDefault') + 2000)),
  '默认应用不写 recents/usage（lk3 不经 pth.t）');

// ── ViewModel 注入接线（qp9.O 等价）──
check(/bundledDefaultApply: \(\(noteId: string\) => Promise<void>\) \| undefined/.test(vm),
  'VM 注入参数 fail-closed');
// Phase 1411：标题经 noteTitleFactory（mcn.g 等价）生成、fail-closed→默认串。
check(/repo\.createNote\(title[\s\S]{0,400}?bundledDefaultApply\(note\.id\)/.test(vm),
  'createNote 后应用默认');
check(/bundledDefaultApply\(note\.id\)[\s\S]{0,200}?catch \(e\)/.test(vm) &&
  /console\.warn/.test(vm), '默认应用失败不回滚笔记（lk3 a() 支路）');
check(/new LibraryViewModel\(noteRepo,/.test(lib) &&
  /applyBundledTemplateDefault\(context, this\.db, noteId\)/.test(lib),
  'LibraryPage 接线 context+db');
check(/import \{ applyBundledTemplateDefault \} from '\.\.\/\.\.\/data\/BundledPaperTemplateApply'/.test(lib),
  'LibraryPage import');

// ── 字符串 ──
check(en.includes('"paper_templates_set_default"') && en.includes('"Set as default"'),
  'en Set as default');
check(zh.includes('"paper_templates_set_default"') && zh.includes('"设为默认"'),
  'zh 设为默认');

console.log(`d02-original-paper-template-default OK — ${n} checks`);
