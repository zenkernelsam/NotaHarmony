# Phase 689 — 原版字体样式预设（hr4 / ote）移植

## 范围

原版 `i31` 字体样式面板的 6 项预设（Large Title/Heading 1-3/Body/Caption）
补进 `TextBlockOverlay`：`ote` → `zyd{bold, italic:false, fontSize}`
三字段原子写，选区改写 + 折叠光标预期属性。

## 原版行为（证据见 phase-689 evidence）

- `hr4` 枚举：LargeTitle(36,b)/H1(30,b)/H2(24,b)/H3(18,b)/Body(14，缺省 K)/
  Caption(12)；`I`=bold、`J`=fontSize。
- `cve` `ote` 分支：`zyd{hr4.I, FALSE, hr4.J}` mask2012 原子写三字段
  （bold 随预设、italic 显式清除、字号预设值），随后 `i(qse.L)` 收面板。
- `cve` `l(f)`：独立字号写 `zyd.f=Float(rh8.u(f,4,72))`（clamp [4,72]）。
- `i31`：面板项点击 → `new ote(hr4Var)`。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `applyTextStylePreset(bold,fontSize)`：单趟区间三切分，mid 原子写
    `{bold, italic:false, fontSize}`，gap-fill 同三元组 —— 忠实于
    mask2012 的原子语义（选预设必清 italic）。
  - 折叠光标：pendingCharStyles 合并 `{bold, italic:false, fontSize}`；
    pending 落地 bold/italic 走既有 fields 循环（`applyCharStyle`
    显式写 false/true），fontSize 走新增 `applyFontSize`。
  - `applyFontSize(size|null)`：字号字段区间写（null 清除；为后续
    `l(f)` 独立字号控件预留）。
  - `buildTextStyleMenu()`：6 项 `bindMenu`，置 `Style` 按钮于格式行
    行首（对应原版 i31 面板在格式工具链中的首位）。
- 新增字符串 ×7（en/zh）：`text_style` + 6 预设名（对照
  `ui_text__font_style_*`）。

## 验证

- Replay：`d02-original-text-style-presets.mjs` 16 项全绿；lease-bound
  enabled 计数 18→19。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 沿用 ADR-0648/0650 登记差异（CRDT 写侧无本地 style-op 编码器等）。
- 样式预设以文本菜单呈现，非原版面板形态；当前选区命中的预设名
  不在按钮上回显（原版面板高亮当前样式，按钮恒显 "Style"——
  受限等价，记入 evidence）。
- `l(f)` 独立字号滑杆/步进控件未实现（预设表已覆盖原版常用档位）。
- 渲染端 `style.fontSize`/`style.familyName` 逐 run 生效（font 令牌），
  但行高/baseline 仍以 `element.fontSize` 计量 —— 混排字号的行距
  与原版的逐 span 行度量存在已知差异（真机清单 R-26 覆盖）。
- 字体族（`nte`/`zq8`：Inter/Roboto/EB Garamond + 下载字体表）、
  文字颜色（`qte`/`zyd.g`）、链接（`tte`/`aue`/`mte`）仍属后续 Phase。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-text-style-presets.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
