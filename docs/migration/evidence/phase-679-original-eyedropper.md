# Phase 679 — 原版 eyedropper（取色器）

- 状态：已实施
- 来源：`decompiled_1.0.3`（只读证据，未修改）

## 原版结构与语义

**入口（`r22.java` case 9）**：色彩面板行渲染 eyedropper 按钮
（`ui_tools__eye_dropper_color_picker` 图标 +
`ui_tools__eyedropper`="Eyedropper" 标签）。

**状态（`lu7.java` / `sc9.java`）**：`sc9` 色彩面板态携带
`eyedropperState`=`lu7{a: enabled, b: pick(ix4<iu1>), c: dismiss
(Function0)}`；`ww1`（色彩面板 VM）经 `i8f.k` 持有。

**开关语义**：

- `i3.java` case 12（显式开关/取消）：`lu7.c.invoke()` 后
  `i8f.k(lu7.a(lu7, null, null, 6))`——mask 6 保留回调、清
  `enabled`，即任何路径结束都自动关。
- `q5.java` case 5（取样提交）：`lu7.b.invoke(iu1)` 把颜色交给
  面板绑定的目标上下文，随后同样 `lu7.a(...,6)` 自动关。
- `u49.java:1484`：`lu7.a` 激活时 chromeFlip（面板翻面反馈）。

**取样（`a3a.java:93`）**：按住/拖动期间对画布 `Bitmap` 取
`getPixel`（坐标 clamp 到 [0,w-1]/[0,h-1]），`kkf.d` 转 `iu1`
写入取样态——实时跟随指尖。

**放大镜（`nui.java`）**：`m18.n(zn9, e76, bitmap, wx4)` 渲染
指尖上方的邻域放大图 + 位置柄。

**旗标**：`ac4.D`=SHOW_EYEDROPPER（无远程键，本地默认开）；
`ac4.C`=EYEDROPPER_ALWAYS_RECORDING（`lsb.c`=
androidEyedropperAlwaysRecording 远程通道）——控制取样色是否
计入最近色。

## Harmony 实现

- `EditorViewModel`：`eyedropperActive`/`eyedropperForSelection`
  + `setEyedropperActive(active, forSelection)`；工具切换路径
  （`applyActiveState` 前）复位——等价 lu7 生命周期。
- `ColorPickerView`：面板顶部 eyedropper 行（accent 高亮激活
  态），点击 `setEyedropperActive(!active, selectionMode)`——
  `selectionMode` 即 lu7.b 的目标上下文。
- `EditorToolbar`：色彩面板关闭 / 粗细面板打开时
  `setEyedropperActive(false)`（面板离场即失效）。
- `NoteCanvasView`：`onCanvasTouch` 在 busy 守卫后拦截
  `eyedropperActive` → `onEyedropperTouch`：
  - DOWN/MOVE → `sampleEyedropper`：`vp2px` 换算 +
    `canvasCtx.getImageData(24px 邻域, clamp)`（a3a 等价），
    中心像素 → ARGB int（kkf.d 等价），邻域 → PixelMap
    （放大镜）；`eyedropperSampleGeneration` 防旧帧覆盖。
  - UP → `commitEyedropper`：选区上下文 →
    `onEyedropperSelectionColor`（NotePage：selectionInkColor +
    signal++，同工具栏取色通道）；工具上下文 →
    `setBrushColor`（含 recents 记录，对应 always-recording 旗标
    已实现的 ehb 语义）；随后 `setEyedropperActive(false)`。
  - CANCEL → `cancelEyedropper`（i3 case12）。
- 放大镜覆盖层：指尖上方 88vp 圆形邻域图 + 中心取样环
  （nui 等价），`overlayWidth` 钳制出界。
- 字符串：`eyedropper`="Eyedropper"/"取色器"。

## 适配差异

- 原版放大镜为系统合成层 loupe；本实现用 `getImageData` 邻域
  PixelMap 圆形裁剪，取样语义一致。
- EYEDROPPER_ALWAYS_RECORDING 为远程旗标；Harmony 现有
  `setBrushColor` 无条件记 recents（ehb parity），与该旗标开启
  态等价——登记为已对齐。

## 验证

- Replay fixture `d02-original-eyedropper.mjs` 26/26；
  全量 563/563（FAIL=0）。
- `note@ohosTest` clean + `note@default` 双 HAP `BUILD SUCCESSFUL`。
- 无设备/模拟器/Hypium 运行时验证。
