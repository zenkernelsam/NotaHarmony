// Phase 727 — font/ + assets/ 资源族收口（三族编辑器字体内置注册 +
//   商业字体/PDFTron/Rive/YouTube 资产边界登记）
// 原版证据：qr4.c/d 三族（Inter 缺省/Roboto/EBGaramond）+ res/font/
//   变量字库文件；assets/pdftron_*、inky/*.riv、ui_designsystem__*.riv、
//   ayp_youtube_player.html。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');
const exists = (p) => fs.existsSync(R(p));

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log(`  FAIL ${name}`); }
};

const fonts = read('note/src/main/ets/data/NoteFonts.ets');
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

// === 字体内置（qr4.c 三族，res/font/ → rawfile/fonts/）===
for (const [family, file] of [
  ['Inter', 'inter.ttf'], ['Roboto', 'roboto.ttf'], ['EBGaramond', 'ebgaramond.ttf']]) {
  check(`rawfile fonts/${file} 已内置`, exists(`note/src/main/resources/rawfile/fonts/${file}`));
  check(`registerFont 注册 ${family}`,
    fonts.includes(`familyName: '${family}'`) && fonts.includes(`fonts/${file}`));
}
check('registerNoteFonts 幂等守卫', fonts.includes('noteFontsRegistered'));
check('注册走 UIContext.getFont()', fonts.includes('getFont().registerFont'));

// === 注册挂点 ===
check('TextBlockOverlay 进编辑面注册', /aboutToAppear[\s\S]*?registerNoteFonts/.test(overlay));
check('NoteCanvasView 画布注册', /aboutToAppear[\s\S]*?registerNoteFonts/.test(canvas));
check('两文件均 import registerNoteFonts',
  overlay.includes("from '../../data/NoteFonts'") && canvas.includes("from '../../data/NoteFonts'"));

// === 选择器三族仍对齐 ===
check('选择器 Inter 项保留', overlay.includes("'Inter'"));
check('选择器 Roboto 项保留', overlay.includes("'Roboto'"));
check('选择器 EB Garamond 项保留', overlay.includes("'EBGaramond'"));

// === 边界登记（ADR-0675）===
const adr = read('docs/migration/adr/ADR-0675-original-font-assets.md');
check('ADR-0675 存在', adr.length > 500);
check('ADR 登记商业字体边界', /gtamericamono|gtflaire|proximasoft|untitledserif/i.test(adr));
check('ADR 登记 PDFTron 资产边界', /pdftron|pdfnet/i.test(adr));
check('ADR 登记 Rive 资产边界', /inky_2026|\.riv|learn_confetti/i.test(adr));
check('ADR 登记 YouTube 播放器资产边界', /ayp_youtube|YouTube/.test(adr));
check('ADR 记录斜体合成/变体差异', /italic|斜体/.test(adr));
check('ADR 记录 qr4.g 旧族名映射', /qr4\.g|NotoSerif|CutiveMono/.test(adr));

const evidence = read('docs/migration/evidence/original-font-assets-jadx-2026-09-25.md');
check('证据文档存在', evidence.length > 400);
check('证据引用 qr4.c 三族', /qr4/.test(evidence) && /Inter/.test(evidence));
check('证据引用 assets/ 清单', /pdfnet|\.riv|ayp_youtube/.test(evidence));

const report = read('docs/migration/reports/phase-727-original-font-assets.md');
check('中文报告存在', report.length > 500);
check('报告引用原版证据', /qr4|registerFont/.test(report) && report.includes('font/'));

console.log(`D02_ORIGINAL_FONT_ASSETS_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
