# Phase 287 修复总结：原版图片 Transform Undo 资产刷新

日期：2026-08-23（Asia/Shanghai）
状态：已完成静态分类修复与验证；真实设备 Undo 重绘仍开放。

## 目标

补审“图片 Undo 后重绘”开放项发现，单图裁剪已经生成 `beforeImages/afterImages` 并推入
`TRANSFORM_ELEMENTS`，但 `actionTouchesImages()` 不识别该类型。Undo/Redo 后共享 bitmap 可能继续使用旧
decode 快照，与新 cropRect 或 flip flags 不一致。本阶段只修复 runtime 资产刷新分类，不扩大持久化协议。

## 实现与证据

- `TRANSFORM_ELEMENTS` 中只要 `beforeImages` 或 `afterImages` 非空，就归类为触碰 image assets；
- 既有 Undo/Redo 会调用 `refreshImageAssets()`，释放共享 bitmap 后按当前 block metadata 重新加载；
- `UndoRedoManager` 已对两个 image snapshot 做内存估算，证明这是 metadata-changing history；
- 单图 crop/flip 的 type-23 durable 边界、nullable register 和 uploadable op 保持不变。
完整记录见 ADR-0265 与 evidence 文件。

## 验证

- 同步 `d02-image-editing.mjs`，移除旧的 `doesNotMatch(TRANSFORM_ELEMENTS)` 断言并改为正向检查；
- 新增专项 Replay：`d02-original-image-transform-undo-asset-refresh.mjs`；
- 专项结果：`D02_ORIGINAL_IMAGE_TRANSFORM_UNDO_ASSET_REFRESH_OK TOTAL=6 FAILED=0`；
- 全量 Replay、clean 双 HAP 与静态检查见总进展补录；未启动模拟器、虚拟机、真机或 Hypium。

## 明确未闭环

- 真实设备 Undo 后重绘、内存峰值、性能与端到端体验；
- 多图跨张事务 rollback；
- oriented-crop 编辑 UI 与全部组合矩阵；
- 相机、Pasteboard、拖放入口；
- `T-042` 继续严格保留为整个 Goal 最后一项。
