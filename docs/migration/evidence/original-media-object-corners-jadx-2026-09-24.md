# 原版 media_object_corners 设置与 corner register — JADX 证据（2026-09-24，Phase 704）

## 设置面

- `feature_settings__media_object_corners` = "Media object corners"；
  选项 `feature_settings__rounded` = "Rounded"、
  `feature_settings__sharp` = "Sharp"（strings.xml）。
- `z22.java` case ~17 渲染标题；`y22.java`/`hx1.java` case 26 渲染
  Rounded/Sharp 两个 `apb.f` 选项行（`ra(19)` 点击回调）。

## corner 是 BlockCommon LWW register（枚举）

- `ry0.java:7` 元数据：`getCorner()Lcom/gingerlabs/notability/core/
  model/flatbuffers/BlockCornerType`——**枚举类型**，非像素半径。
- `ry0.java:151`：`BlockCommonImpl` 含 `cornerRegister`（与
  rotation/scale/size/textWrap/caption/positionLocked/zIndex 并列）。
- `mb.java:25`：`cornerRegister` builder；`td8.java:243`：
  ModifyBlock op `toString` 含 `corner=`；`rl2.java:273` 同。
- `td8.java:74`：equals 比较 `k() == td8Var.k()`（corner）。

## Harmony 数据面（已对齐）

- `ElementTypes.ets`：TEXT（`corner?: number`）/IMAGE（`corner:
  number`）/MATH（`corner: number`）元素字段。
- `OriginalCreateBlockOperation.ets:181`：
  `corner: normalizeOriginalEnum(table.readUint8(1,0),1)`——
  枚举 {0,1}；`:373` `create_corner` 列；`:452/490/517` 应用到
  三类元素；`:702` 读回校验。
- `OriginalModifyBlockOperation.ets`：`corner: StoredRegister
  <number>`（:93）；`table.hasField(1)` 读取（:269）；
  `registerAccepts` LWW 合并（:411-412）；`updatedElement.corner`
  落值（:470）。
- 插入种子：`OriginalImageInsertPlan.ets:226` `corner: 0`；
  `OriginalMathInsertPlan.ets:81` `corner: 0`；`NoteCanvasView.ets
  :9364`（TEXT draft）`element.corner = 0`。

## 未对齐面（登记边界）

1. `media_object_corners` 设置项与 Rounded/Sharp 选项：Harmony
   `EditorSettingsStore` 无此偏好，设置页无此行。
2. ROUND 视觉渲染：Harmony 渲染器无一处消费 `element.corner`
   （grep 全部命中命中测试/选区）。且此前
   `original-text-transform-selection-eraser-jadx-2026-08-17.md`
   已记录："ROUND Text corner 的原版像素半径仍无静态证据，
   本阶段继续不猜"——本 Phase 沿用该先例。
3. 枚举序推断：SHARP=0（默认/插入种子）、ROUND=1——与
   `normalizeOriginalEnum(...,1)` 上限一致。

## 结论

corner 的 CRDT 数据面（create/modify op + 元素字段 + 持久化列）
已完整 round-trip；设置项与 ROUND 视觉渲染按 ADR-0653 登记
fail-closed（SHARP=0 为确定默认，ROUND 半径无证据不猜）。
