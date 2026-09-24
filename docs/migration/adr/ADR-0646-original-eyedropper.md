# ADR-0646 — 原版 eyedropper 移植（lu7 状态机 + a3a 取样 + nui 放大镜）

- 状态：Accepted
- Phase 679；对齐 `lu7`/`sc9`（decompiled_1.0.3）、`r22` case9、
  `i3` case12、`q5` case5、`a3a`、`nui`、`u49:1484`、
  `ac4.C`/`ac4.D`。

## 背景

原版色彩面板携带 eyedropper：`sc9.eyedropperState`=`lu7`{enabled,
pick(ix4), dismiss}。开启后面板翻面（chromeFlip），画布触摸由
`a3a` 接管——指尖处 `Bitmap.getPixel`（clamp）实时取样，`nui`
渲染邻域放大镜；松开 `q5` case5 把 `iu1` 交给面板绑定上下文
（工具色或选区色）并 `lu7.a(...,6)` 自动关；显式关 `i3` case12
同式复位。

## 决策

1. `EditorViewModel` 持有 `eyedropperActive`/`eyedropperForSelection`
   （对应 lu7.a 与其目标上下文），`setEyedropperActive` 为唯一
   状态入口；工具切换、色彩面板关闭、粗细面板打开均复位。
2. `NoteCanvasView.onCanvasTouch` 在 busy 守卫后整体拦截
   `eyedropperActive`——激活期间画布不产生笔迹/选区/其他交互，
   与原版「取样接管」一致。
3. 取样走 `CanvasRenderingContext2D.getImageData`（24px 邻域、
   clamp），中心像素 → ARGB int（`kkf.d` 等价）；邻域 →
   `image.createPixelMap` 供放大镜。`createPixelMap` 为异步，
   `eyedropperSampleGeneration` 丢弃过期帧。
4. 提交分派：`eyedropperForSelection` →
   `onEyedropperSelectionColor`（NotePage 写 selectionInkColor +
   `selectionColorSignal++`，复用工具栏选区取色通道）；否则
   `setBrushColor`（含 recents 记录——与 EYEDROPPER_ALWAYS_
   RECORDING 旗标开启态等价，旗标本体为远程通道登记）。
5. 放大镜 = 指尖上方 88vp 圆形邻域 PixelMap + 中心取样环，
   `overlayWidth` 钳制出界（nui `e76` 位置柄等价）。

## 后果

- 真实本地功能落地，无旗标/服务端依赖（SHOW_EYEDROPPER 无远程
  键即默认开）。
- 取样只在 eyedropperActive 期间发生；退出路径全部经
  `setEyedropperActive(false)` + `clearEyedropperSampling`
  （PixelMap release）。
- 无运行时验证时，取色正确性由 fixture 的结构钉 + getImageData
  语义保证。

## 验证

- Replay `d02-original-eyedropper.mjs` 26/26；全量 563/563。
- `note@ohosTest` clean + `note@default` 双 HAP `BUILD SUCCESSFUL`。
- 无设备/模拟器/Hypium 运行时验证。
