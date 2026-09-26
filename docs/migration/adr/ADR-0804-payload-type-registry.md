# ADR-0804 — zq9 表↔类型权威注册表与 Op 信封写入器登记

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `zq9` static init 的 `mx7` map = 31 条「表类 ↔ haa 类型」权威映射
  （l2d→SET_METADATA … ud8→MODIFY_COMMENT）；未映射类经 `rgc.b` 抛异常。
- `zq9.e` Op 信封写入器：startTable(7) + id@0（qo5 内联）+
  clientTime/serverTime/audioTime u64 可选 + payloadType@4 byte（默认
  NONE）+ payload@5 间接表 + transientInteraction@6 可选；
  `z(iN,4)`/`z(iN,14)` 标记 **id 与 payload 均为 required**。
- `sdf` = TransientInteraction{interactionId@0 qo5、timeout@1 mmf} —
  Op 上的可空瞬态标记副信道，区别于 type-26 的 `tdf` ENDED 负载本体。

## Harmony 决策

- 31 个 `ORIGINAL_*_PAYLOAD_TYPE` 常量与 zq9 逐值一致；`supports()`
  分发镜像 `b()` 查表 + 未知类 fail-closed。
- 解码侧「type≠0 必须载 payload」+「id@0 required」门对应原版
  required(0)/required(5)。
- `tdf`（type-26）与 `sdf`（副信道字段）分物登记：Harmony 的
  `OriginalTransientInteractionPayloadEncoder` 编码前者
  （interactionId + replacedByOp 双恒等槽）。

## Parity 状态

- 等价：全 31 类型映射闭卷对齐；required 语义与 fail-closed 方向一致。
- 无缺口：`sdf` 副信道在 Harmony 以对应编码器/解析路径覆盖同语义。

## 验证

- `d02-payload-type-registry.mjs`：42/42 通过（31 映射逐条断言 +
  Harmony 常量逐值复核）。
- 全量 Replay 与双 HAP 构建见 Phase 860 报告/提交。
