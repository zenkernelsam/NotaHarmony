# Phase 691 — 原版字体族（nte → zyd.e familyName）移植

## 范围

原版 `i31` 字体面板字体族区（`nte(zq8)` → `zyd.e`）补进
`TextBlockOverlay`：`familyName` 字符 run 的写入、选区应用、折叠
光标预期属性与 Default 缺省恢复。渲染端字体令牌此前已就位。

## 原版行为（证据见 phase-691 evidence）

- `cve` `nte` 分支：`zyd{...,zq8.a,...}` mask2031 写 familyName
  （modelName），`i(qse.N)` 收面板。
- `zq8` = NbFont{modelName, displayName, fontFamily}；
  `qr4.c/d` 三随包字体 Inter(缺省 b)/Roboto/EBGaramond；
  `qr4.g` 六下载字体为服务端资源。
- `i31`：字体族项 → `new nte(zq8Var)`。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `applyFontFamily(name|null)`：区间三切分写 `familyName`；
    `null`→`undefined`（JSON 规范归并剔空），非 null gap-fill。
  - `pickFontFamily(name)`：选区写 run；折叠光标写
    `pendingCharStyles.familyName`。
  - `clearFontFamily()`（Default）：选区 `applyFontFamily(null)`；
    折叠 `pendingClearFamily`。
  - `buildFontMenu()`：Inter/Roboto/EB Garamond（displayName 展示、
    modelName 落库）+ Default；`Font` 钮置 Style 与 Bold 之间
    （对应原版 i31 面板中样式→字体族的邻位）。
- 新增字符串 ×2（en/zh）：`font_family`="Font"/"字体"、
  `font_default`="Default"/"默认"。

## 验证

- Replay：`d02-original-font-family.mjs` 16 项全绿；lease-bound
  enabled 计数 22→23。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 原版字体文件未内嵌：`familyName` 忠实持久化，渲染按 HarmonyOS
  字体名匹配回退（字形差异=运行环境限制，记 evidence 受限等价；
  字体资源内嵌为后续工程项）。
- `qr4.g` 下载字体（NotoSerif/NotoSansMono/CutiveMono/DancingScript/
  ComingSoon/CarroisGothicSC）为服务端资源，未移植。
- 菜单为文本列表，无原版面板的字体预览。
- 沿用 ADR-0648/0650 登记差异。
- 链接（`tte`/`aue`/`mte`）仍属后续 Phase。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-font-family.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
