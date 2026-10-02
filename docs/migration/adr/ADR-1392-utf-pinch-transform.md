# ADR-1392：utf(PinchTransform) 双指选区变换会话移植

- 状态：已采纳
- Phase：1457

## 背景

原版 1.4.2 选区手势族除 xtf/vtf/wtf/ttf 外还有 `utf`：
双指捏合直接变换**选区内容**（等比缩放 + 吸附旋转），与视口
捏合缩放是两个不同语义面。Harmony 此前双指只做视口
zoom/pan，第二指按下即取消进行中交互——utf 整体缺失。

## 原版语义（证据见 phase-1457-utf-pinch-transform.md）

- `guf.y`：第二指按下时建立 utf——无活动变换会话、选区有效、
  非点除/全锁定/进行中选区、第二指落在旋转系选区界内；
  枢轴 = 第二指触点。
- `guf.v`：`f` = 等比缩放（双指距离比），`f2` = 连线角增量经
  `twm.d` 吸附最近 90° 倍数（±5° 阈值）；`guf.m` 应用
  `T(p)·R·S·T(−p)·base`；结束时 `a.c` 提交，选区保留。

## 决策

1. `onTouchDown` 多点分支在 `cancelActiveInteraction` 之前插入
   `tryStartSelectionPinch`：复用 `pointInSelectionRect` 的旋转
   判定做界内测试；捕获 `dragBefore*` 快照、`pinchBaseTransform`
   与初始距离/连线角。
2. `onTouchMove` 中 pinch 会话优先于多点取消早退；每帧
   `applySelectionPinch` 重建 `R(p)·S(p)·base`（锚点与旋转中心
   同取枢轴时与原版 `guf.m` 的 `T(p)·R·S·T(−p)` 等价），枢轴逐帧
   更新为双指中点。
3. `onTouchUp`：剩余手指数 < 2 时 `endSelectionPinchCommit` ——
   单次 `TRANSFORM_ELEMENTS` 撤销记录 + persist + 保留选区。
4. 声明式 `PinchGesture`/`PanGesture` 的 `onActionUpdate` 加
   `pinchSelectSession` 门——utf 会话期不驱动视口 zoom/pan；
   无会话时视口手势行为不变。
5. `twm.d` 吸附与 Phase 1453 旋转柄共用 `SELECTION_ROTATE_SNAP_RAD`
   （5°）+ 新增 `SELECTION_ROTATE_SNAP_STEP`（π/2）。

## 已知差异（登记）

- 原版第二指命中用 `rtf.b().a` 旋转系精确界测试；Harmony 复用
  `pointInSelectionRect`（含 `uniformSelectionCarrierRadians`
  旋转判定），语义等价但判定路径不同。
- `lsf.c`（showUncroppedImage）门未单独移植——Harmony 无对应
  裁剪图未裁剪显示态，按 `selectionPositionLocked` + deselectMode
  覆盖主要排除语义。
- `guf.m` 的 `z=true` 页框钳制（提交时把成员拉回页内）未实现；
  Harmony 提交不钳制页框，登记为版本差异。
- ArkUI 声明式手势与触摸分发并行：utf 会话由触摸路径建立后靠
  门控抑制视口手势回调，二者不同时生效。

## 验证

- `d02-original-pinch-session-utf.mjs`：22 项断言（字段、建立门、
  更新语义、吸附、提交、取消、视口门控）全绿。
- 全量基线 + `note@default` + `note@ohosTest` 构建。
