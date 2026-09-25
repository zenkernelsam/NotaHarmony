# 原版 font/ + assets/ 资源证据（JADX 1.0.3 decompiled）

日期：2026-09-25。来源：`decompiled_1.0.3/resources/res/font/`、
`decompiled_1.0.3/assets/`、`sources/defpackage/qr4.java`。

## qr4.java — 文本字体族注册表

```java
kr4 kr4VarB  = aa6.b(tl7.a(R.font.roboto_variablefont, ...),
    tl7.a(R.font.roboto_bold, ...), tl7.a(R.font.roboto_italic_variablefont, ...));
kr4 kr4VarB2 = aa6.b(tl7.a(R.font.inter_variablefont_opszwght, ...),
    tl7.a(R.font.inter_italic_variablefont_opszwght, ...));
kr4 kr4VarB3 = aa6.b(tl7.a(R.font.ebgaramond_variablefont, ...),
    tl7.a(R.font.ebgaramond_italic_variablefont, ...));
zq8 zq8Var = new zq8("Inter", "Inter", kr4VarB2);
List c = m18.m0(zq8Var, new zq8("Roboto", "Roboto", kr4VarB),
    new zq8("EBGaramond", "EB Garamond", kr4VarB3));
b = zq8Var;   // 缺省 = Inter
```

`qr4.b(str)` 按 familyName 反查，miss → 缺省 Inter。

`qr4.g` 旧族名展示别名表（旧版内置字体，现不再打包）：
NotoSerif→"Noto Serif"、NotoSansMono→"Noto Sans Mono"、
CutiveMono→"Cutive Mono"、DancingScript→"Dancing Script"、
ComingSoon→"Coming Soon"、CarroisGothicSC→"Carrois Gothic SC"。

## res/font/ 清单（许可分流）

开源许可（拷入 Harmony `rawfile/fonts/`）：
- `inter_variablefont_opszwght.ttf`（874,708 B，OFL）
- `roboto_variablefont.ttf`（468,308 B，Apache-2.0）
- `ebgaramond_variablefont.ttf`（934,420 B，OFL）
- `inter_italic_variablefont_opszwght.ttf`、`roboto_bold.ttf`、
  `roboto_italic_variablefont.ttf`、`ebgaramond_italic_variablefont.ttf`
  ——变体文件：Harmony registerFont 一族一源，变量字重走 wght 轴、
  斜体合成（见 ADR-0675 差异节）。

商业许可（不拷入，upsell/品牌面用）：
- `gtamericamono_bold.otf`、`gtflairebasic_black.otf`、
  `gtflairebasic_extra.otf`、`proximasoft_{bold,medium,regular}.otf`、
  `untitledserif_{regular,regular_italic,medium,bold}.otf`

## assets/ 清单

| 资产 | 归属 |
|---|---|
| `feature_note_inky__inky_2026_v32.riv` | Inky 吉祥物 Rive（ADR-0656 fail-closed） |
| `ui_designsystem__anim_grow/learn/memorize/productivity.riv` | Learn/ onboarding 插画动效 |
| `ui_designsystem__learn_confetti.riv` | Learn 庆祝动效 |
| `ayp_youtube_player.html` | Android YouTube Player iframe 模板（youtube_* 导入面，ADR-0651） |
| `pdfnet.res`、`pdftron_{exotic_font,layout,smart_substitution}_resources.plugin` | PDFTron 引擎私有资源（Harmony 用 PDFKit） |

## 结论

- 编辑器三族字库为可移植开源资产，已内置+注册（`NoteFonts.ets`）。
- 商业字体、PDFTron 资源、Rive 动效、YouTube 模板全部落在既有
  fail-closed 面或平台引擎差异上，逐键登记。
