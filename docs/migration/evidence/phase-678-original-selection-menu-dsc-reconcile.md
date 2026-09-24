# Phase 678 — 原版选区菜单 `dsc` 22 项全表对账

- 状态：已实施（fail-closed 登记；无行为变更）
- 来源：`decompiled_1.0.3`（只读证据，未修改）

## 原版枚举与派发

`dsc.java:30-74` — 选区菜单动作共 **22 项**：

| ordinal | dsc | 处理（`dhb` case13 内） | Harmony `SelectionMenuAction` |
| --- | --- | --- | --- |
| 0 | STYLE | 合并选区颜色/宽度 → 样式面板 | STYLE（19） |
| 1 | COPY | 复制到剪贴板 | COPY（0） |
| 2 | CUT | 剪切 | CUT（1） |
| 3 | DUPLICATE | 复制选区 | DUPLICATE（14） |
| 4 | GROUP | 成组 | GROUP（11） |
| 5 | UNGROUP | 解组 | UNGROUP（12） |
| 6–9 | SEND_FORWARD/BACKWARD/TO_FRONT/TO_BACK | z 序 | SEND_*（3/4/15/16） |
| 10 | DELETE | 删除 | DELETE（2） |
| 11 | CONVERT_TO_MATH | MyScript 转换管线（见下） | **缺** |
| 12 | CONVERT_TO_TEXT | MyScript 转换管线（见下） | **缺** |
| 13 | EDIT_MATH | 打开数学编辑 | EDIT_MATH（13） |
| 14 | CROP | 图像裁剪 | CROP（9） |
| 15 | FIT_TO_PAGE | `dhb:17985` → `throw new NotImplementedError(0)` | **缺（原版即死桩）** |
| 16–17 | FLIP_HORIZONTALLY/VERTICALLY | 翻转 | FLIP_H/V（5/6） |
| 18 | LOCK | 锁定位置 | LOCK（10，合并 UNLOCK） |
| 19 | UNLOCK | 解锁 | （并入 LOCK 开关，ADR-0586） |
| 20 | DESELECT | 取消选择 | DESELECT（7） |
| 21 | MORE | `dhb:18045` 翻转 `msc.b`（子菜单显隐） | **缺（单行适配）** |

Harmony 另有 `PASTE`（8；原版为浮动粘贴 chip 的注册适配）与
`DESELECT_CONFIRM/CANCEL`（17/18；原版 deselectMode 的 `k2f`
确认/取消）。`SelectionOverlay.ets` 菜单构造已按原版 dsc 顺序排列
（`SelectionOverlay.ets:147-151` 注释）。

## CONVERT_TO_MATH / CONVERT_TO_TEXT — MyScript iink 管线

`dhb` case11/12（`dhb.java:17696/17811`）语义一致：

1. `xsc.p()`（`xsc.java:276`）— 探测转换后端
   `j4e`/`d4e`/`v2e`（`tqd` 识别会话，`j4e.java:10`）。
2. `ba6.o(asdVar.value, isc.a/jsc.a)` — 页面类型门禁。
3. `ktc.h()` 平铺选区成员 → `tl7.x` 收集 `s06` 笔画；
   CONVERT_TO_TEXT 另过 `wqh.e` 笔画过滤。
4. `xsc.v(strokes, onSpanPages)` — 跨页校验；跨页时
   `xsc.u()/t()` 提示 "Text/Math conversion selection spans pages"。
5. 识别 → 成功回调替换选区为数学/文本块；失败回调
   `showMathConversionFailure` 等。

后端为 **MyScript Interactive Ink SDK**（`com.myscript.iink` 包随
APK 打包）——商业闭源组件。

## Harmony 现状

`OriginalHandwritingConversionCoordinator`
（`note/src/main/ets/core/adaptation/`）已按原版语义搭建完整管线：
`runOriginalHandwritingConversion(request)` 接收 `selectedStrokeIds` +
`pageStrokes` 快照，经 recognizer → planner → freshness 校验 →
persistence；全部失败以 outcome 返回而非抛出。

但 `OriginalHandwritingRecognitionProvider`（`recognizeText(strokes,
localeCode)`）**仅有测试桩，无生产实现**——HarmonyOS 无 MyScript
iink 等价物。与原版 `xsc.p()` 后端不可用 → 菜单项不渲染的门禁
语义一致：**菜单正确缺省 = fail-closed 对齐**。

## FIT_TO_PAGE — 原版死桩

`dhb:17985`：`case 15: throw new NotImplementedError(0)`。
菜单项可渲染但点击即抛——1.0.3 的未完成桩。Harmony 缺省正确。

## MORE — 双行菜单结构

`msc`（`msc.java`）= `ShowMenuOptions(options=esc{primary 行,
submenu 行}, showSubmenu=b, selectionHasRotationHandle=c)`；
`dhb` case21 仅翻转 `showSubmenu`。原版菜单为两行 + "More"
人字形展开（`ux9:2512` 渲染 `selection_menu_more` + 方向感知
chevron）。Harmony 单行 `bindMenu` 全量列出——已注册适配
（SelectionOverlay 顶部注释）。

## 结论

- 缺省 4 项均属服务端/闭源/死桩/适配域，无一可用本地语义补齐。
- 不虚构 CONVERT_* 项：无 OCR 后端时渲染死按钮违背原版
  `xsc.p()` 门禁语义。
- 待 `OriginalHandwritingRecognitionProvider` 有生产实现后，
  按 `dhb` case12 管线接入 `runOriginalHandwritingConversion`
  即可恢复 CONVERT_TO_TEXT；CONVERT_TO_MATH 需另建数学识别器。

## 验证

- Replay fixture `d02-original-selection-menu-dsc-reconcile.mjs`
  43/43；全量 562/562（FAIL=0）。
- `note@ohosTest` clean + `note@default` 双 HAP `BUILD SUCCESSFUL`。
- 无设备/模拟器/Hypium 运行时验证。
