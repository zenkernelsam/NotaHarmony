// 原版 qr4.c：文本字体族三选一 —— Inter（缺省 b=zq8Var）/ Roboto /
// EBGaramond，原版在 res/font/ 内置变量字库（OFL/Apache 开源许可）。
// Harmony：字库拷入 rawfile/fonts/ 并经 UIContext.registerFont 注册到
// 当前窗口字体表，使 Canvas2DTextRenderer 生成的 fontFamily "Inter" 等
// 解析命中真实字形而非系统回退。
// 原版每族另载粗/斜体变体文件；Harmony registerFont 一族一源，
// 变量字含 wght 轴覆盖字重，斜体由渲染器合成——差异记入 ADR-0675。

let noteFontsRegistered: boolean = false;

export function registerNoteFonts(uiContext: UIContext): void {
  if (noteFontsRegistered) {
    return;
  }
  noteFontsRegistered = true;
  try {
    uiContext.getFont().registerFont({ familyName: 'Inter',
      familySrc: $rawfile('fonts/inter.ttf') });
    uiContext.getFont().registerFont({ familyName: 'Roboto',
      familySrc: $rawfile('fonts/roboto.ttf') });
    uiContext.getFont().registerFont({ familyName: 'EBGaramond',
      familySrc: $rawfile('fonts/ebgaramond.ttf') });
  } catch (e) {
    console.error(`note font registration failed: ${JSON.stringify(e)}`);
  }
}
