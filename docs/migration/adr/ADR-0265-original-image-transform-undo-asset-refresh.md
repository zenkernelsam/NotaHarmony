# ADR-0265：原版图片 Transform Undo 的资产刷新分类

- 状态：Accepted（Phase 287，2026-08-23）
- 范围：IMAGE crop / flip / transform → runtime history → image asset lifecycle
- 相关：ADR-0258（图片插入持久化）、ADR-0262（显示方向）、ADR-0264（组合顺序）

## 决策

`actionTouchesImages()` 必须把包含 `beforeImages` 或 `afterImages` 的 `TRANSFORM_ELEMENTS` 视为触碰
image asset。这样 Undo/Redo 裁剪或翻转后会释放并重新加载共享 bitmap，避免旧解码快照与新 cropRect/
flip flags 不一致。

该修复不改变持久化协议，也不把 crop/flip 从既有 type-23 `MODIFY_BLOCK` durable 边界迁移到其他操作；它只
修正 runtime history 应用后的资源刷新分类。

## 原版对齐与 Harmony 差距

Android 图片加载器按请求参数缓存 drawable；block metadata 变化后不能继续把旧像素快照当作有效结果。
Harmony 的 `ImageAssetLoader` 返回共享 `LoadedImageAsset`，因此 metadata-changing history 必须显式刷新。
裁剪确认已经生成 `beforeImages/afterImages` 并进入 `TRANSFORM_ELEMENTS`；缺口只在刷新分类遗漏。

## 明确边界

- 单张图 crop/flip 的 durable 原子性、nullable register 和 uploadable op 已由此前阶段覆盖，本阶段不改；
- 多图跨张事务 rollback 仍开放；
- 真实设备 Undo 后重绘、内存峰值和性能仍开放；
- `T-042` 继续保留为整个 Goal 最后一项。
