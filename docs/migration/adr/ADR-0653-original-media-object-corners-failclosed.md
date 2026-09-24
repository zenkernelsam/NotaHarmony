# ADR-0653 「Media object corners」设置与 ROUND 圆角渲染 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：704
- 接续：ADR-0014（CreateBlock 公共 register 域）、原文字变换
  选择擦除证据（ROUND Text corner 像素半径"继续不猜"先例）
- 证据：`docs/migration/evidence/original-media-object-corners-jadx-2026-09-24.md`

## 背景

原版设置页含 "Media object corners"（`feature_settings__media_
object_corners`，`z22.java` case ~17 标签 + `y22`/`hx1` 渲染
`feature_settings__rounded`/`feature_settings__sharp` 选项）。

`corner` 是 BlockCommon 的 LWW register（`ry0.java` 元数据：
`getCorner()Lcom/…/flatbuffers/BlockCornerType`，**枚举类型**）；
`td8`/`rl2`/`mb` 显示 `corner` 经 `cornerRegister` 参与 ModifyBlock
op 序列化与相等性比较。

Harmony 现状（已对齐部分）：

- `ElementTypes.ets`：TEXT/IMAGE/MATH 元素均携带 `corner: number`；
- `OriginalCreateBlockOperation`：`corner` uint8 字段
  `normalizeOriginalEnum(table.readUint8(1,0),1)`（枚举 {0,1}），
  持久化 `create_corner` 列并应用到元素；
- `OriginalModifyBlockOperation`：`corner` 走
  `StoredRegister<number>` LWW 合并（`registerAccepts` →
  `updatedElement.corner`）；
- 即 **corner 的 CRDT 数据面已完整 round-trip**。

## 决定

1. **不实现 `media_object_corners` 设置项**：该偏好仅决定新插入
   媒体块 `corner` 寄存器种子（SHARP=0/ROUND=1）。Harmony 插入
   路径固定 `corner: 0`（SHARP）——等价于原版设置保持 SHARP。
2. **不实现 ROUND 圆角视觉渲染**：`BlockCornerType` 的像素半径
   在 decompiled 面无静态证据（此前阶段已记录"继续不猜"先例）。
   无证据猜半径会引入不可逆的视觉偏差；SHARP=0 是确定的默认。
3. **保留 register 数据面**：外部同步/导入携带 `corner=1` 的块，
   Harmony 忠实存储与回写（同步往返不丢数据），仅视觉按 SHARP
   呈现——fail-closed 的呈现降级而非数据丢失。

## 后果

- 原版 SHARP（默认）体验与 Harmony 完全一致；
- 原版用户切到 ROUNDed 的笔记在 Harmony 中数据无损、视觉方角；
  回同步后 corner=1 仍保留，回到原版设备即恢复圆角；
- 若将来获得 ROUND 像素半径证据（真机截图/新反编译资料），
  本 ADR 可单独重开渲染项而不触碰数据面。
