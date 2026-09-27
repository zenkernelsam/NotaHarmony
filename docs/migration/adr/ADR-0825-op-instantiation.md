# ADR-0825 — `wq9`/`xq9` op 实例化层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，classes2.dex 实名）

- `wq9` = `OpCreationMetadata{payload:cee, transient:b,
  inProgressTransientId:c, transientTimeout(省略参数3),
  audioTime:d}`；Kotlin 存根掩码 30 = 全默认；`&2/4/16`
  → transientId/transient/audioTime 默认。
- 自动 transient：`z || transientId!=null || payloadType
  ∈ {26,29}`。
- `xq9.a` = 实例化 lambda：双计数器（瞬态/持久分占序号
  空间）、`rh8.b(counter,site)`→qo5、transient→`sdf`
  C(2){inProgressTransientId}、`zq9.e`→uq9 七字段信封、
  索引入 ops 向量、返回新 qo5。
- `rh8.b`/`rh8.O` = qo5 构造/序列化原语。

## Harmony 决策

`OpStoreImpl`/`nextOperationTimestamp` = 序号分配；
`StrokePersistence` 已引 `xq9 transaction`；sdf/zq9.e 与
`OriginalPeerInteractionOperation` 及信封编码器对齐。

## Parity 状态

等价（op 创建调用链实名对齐；瞬态序号空间由
timestamp/siteId 分配等价表达）。

## 验证

- `d02-op-instantiation.mjs`：22/22 通过。
- 全量 Replay 与双 HAP 构建见 Phase 881 提交。
