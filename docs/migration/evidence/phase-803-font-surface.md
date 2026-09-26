# Phase 803 证据：字体资产面收口

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/resources/res/font/`、`values/public.xml`、
`note/src/main/ets/data/NoteFonts.ets`、`note/src/main/resources/rawfile/fonts/`

## 1. 版本间 delta

`res/font/` 目录两版均为 17 项字体文件（10 otf + 7 ttf；PDFTron exotic
插件位于 `res/raw/`）。
唯一差异：

```
inter_italic_variablefont_opszwght.ttf → inter_italic_variablefont_wght.ttf
inter_variablefont_opszwght.ttf        → inter_variablefont_wght.ttf
```

即 Phase 791 已登记的 Inter 变量轴重命名（opsz+wght 双轴 → wght 单轴）。
字体族构成零变化。

## 2. 原版字体清单（7 族 17 文件）

| 族 | 文件 | 用途分类 |
|----|------|----------|
| Inter | variable_wght + italic | **笔记文本族**（默认） |
| Roboto | variable + italic + bold | **笔记文本族** |
| EBGaramond | variable + italic | **笔记文本族** |
| ProximaSoft | regular/medium/bold | 品牌 UI 字（Compose chrome） |
| UntitledSerif | regular/medium/bold/italic | 品牌展示字 |
| GTFlaireBasic | black/extra | 品牌展示字 |
| GTAmericaMono | bold | 品牌等宽点缀 |
| （非字体） | `pdftron_exotic_font_resources.plugin` | PDFTron 供应商字体包（791 fail-closed） |

## 3. Harmony 侧映射

- **笔记文本三族已完整移植**：`NoteFonts.ets` 经 `UIContext.registerFont`
  注册 Inter/Roboto/EBGaramond（每族一源，变量 wght 轴覆盖字重，斜体由
  渲染器合成）——与原版 `qr4.c` 的三族选择器语义一致（ADR-0675）。
- **品牌 UI 四族未移植**：ProximaSoft/UntitledSerif/GTFlaire/GTAmericaMono
  在 Compose 代码中经 `R.font.*` 编程式引用，用于品牌化 chrome/展示文案
  （库页眉、付费墙、引导页、gallery 等）。其中付费墙/gallery 属 fail-closed
  后端绑定面；其余 chrome 文案 Harmony 使用系统字体（HarmonyOS Sans）渲染，
  属视觉风格差异而非功能缺口。
- 原版 styles.xml 的 `sec-roboto-light`/`sec` fontFamily 为 Samsung 主题
  定制属性，与应用字体无关，无需映射。

## 4. 结论

字体资产面收口：用户可见的笔记字体选择器三族完整对齐（含 ADR-0675
已记录的字重/斜体合成差异）；品牌展示四族登记为 chrome-only 视觉差异，
随后端绑定面 fail-closed；版本间唯一 delta 为已登记的 Inter 轴重命名。
