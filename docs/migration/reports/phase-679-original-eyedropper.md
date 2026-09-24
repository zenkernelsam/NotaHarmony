# Phase 679 — 原版 eyedropper（取色器）移植

- 日期：2026-09-22
- 状态：已完成
- ADR：ADR-0646
- 证据：`docs/migration/evidence/phase-679-original-eyedropper.md`
- Fixture：`docs/migration/replays/d02-original-eyedropper.mjs`（26/26）

## 范围

补 `ac4` 旗标对账中发现的最后一个本地工具面缺口：色彩面板的
eyedropper。原版链路：`r22` case9 面板按钮 → `lu7`{enabled, pick,
dismiss} 激活 → `a3a` 画布 `Bitmap.getPixel` 实时取样 + `nui`
放大镜 → `q5` case5 提交 `iu1` 到绑定上下文（工具色/选区色）并
`lu7.a(...,6)` 自动关；`i3` case12 显式关同式复位。

## Harmony 变更

| 文件 | 变更 |
| --- | --- |
| `EditorViewModel.ets` | `eyedropperActive`/`eyedropperForSelection` + `setEyedropperActive`；工具切换复位 |
| `ColorPicker.ets` | 面板 eyedropper 行（accent 激活态），toggle 透传 `selectionMode` |
| `EditorToolbar.ets` | 色彩面板关闭/粗细面板打开 → `setEyedropperActive(false)` |
| `NoteCanvasView.ets` | 触摸拦截 + `sampleEyedropper`（getImageData 24px 邻域 + PixelMap + generation 防旧帧）+ `commitEyedropper`（工具/选区两路）+ `cancelEyedropper` + 88vp 圆形放大镜覆盖层 + aboutToDisappear 清理 |
| `NotePage.ets` | `onEyedropperSelectionColor` → selectionInkColor + `selectionColorSignal++` |
| `string.json`×2 | `eyedropper`="Eyedropper"/"取色器" |

## 语义对齐点

- **激活即接管**：`eyedropperActive` 期间画布交互全部转为取样
  （busy 守卫后最先判定）。
- **松开提交 + 自动关**：q5 case5 等价——提交后
  `setEyedropperActive(false)`。
- **取消放弃**：CANCEL 走 `cancelEyedropper`（i3 case12）。
- **上下文分派**：`selectionMode` 时色值进选区通道，否则进
  `setBrushColor`（含 recents 记录——always-recording 旗标等价）。
- **放大镜**：指尖上方圆形邻域放大图 + 中心取样环（nui `e76`
  位置柄等价）。

## 验证

- 专用 fixture：26/26（旗标钉 + lu7 状态钉 + 取样钉 + Harmony
  实现钉 + 字符串钉）。
- 全量 Desktop Replay：563/563，FAIL=0。
- `note@ohosTest` clean HAP：BUILD SUCCESSFUL。
- `note@default` HAP：BUILD SUCCESSFUL。
- 构建仅含既有 deprecation/exception 警告，无编译错误。
- 未进行设备/模拟器/Hypium 运行时验证。

## 后续

真机验证项已属既有清单范畴（触摸取样/放大镜跟随/选区取色应用）
——归入 Phase 676 补遗的画布触摸类验证。
