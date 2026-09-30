# ADR-1268：`haa` 全 op 覆盖

## 状态

已接受（Phase 1324）。

## 决策

原版 `haa` 30-op → Harmony `Original*Operation`
（applier)+`PayloadEncoder`（编码器）逐 op 桥接 —
— 全 op 集覆盖+线保真。

## 理由

`haa` 30-op（CONSTRUCTOR/WRAPPED 为 meta）各有
Harmony `Original*` 对应（CreateBlock/Ink/Page/Shape/
Recording、Modify*、DeleteEntities、SetMetadata、
PeerInteraction、UpdateCheckbox、AddPathElements、
AssetCloudPersisted、Comment、Group、Transient
Interaction、text-mutation 等）—— 逐 op 编码+
应用保真。

## 后果

Harmony CRDT op 集与原版 1:1 桥接（`ORIGINAL_*`）+
元素级本地扩展 —— op 覆盖完备。
