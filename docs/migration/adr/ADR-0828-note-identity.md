# ADR-0828 — `ye9`/`led`/`ttf` 标识层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ttf` = 128 位 UUID 值类 `{I,J:long}`（utf 线结构之
  内存对）；`a()`=16B 大端、`toString()`=36 字符标准式、
  `K`=NIL、Comparable+Serializable。
- `led` = `{a:short}` 编辑站值类。
- `ye9` = 会话上下文接口：`c()`→ttf、`d()`→led（null→
  tzc fail-closed）。
- 双形态约定：utf=线结构、ttf=模型值类（同 UUID 两表示）。

## Harmony 决策

`OriginalNoteBundlePageIdentity` 的 `readInlineBytes(0,16)`
+`decodeOriginalUuid` 与 `ttf.a()` 字节序等价；siteId ↔
`OperationIdentity.siteId`；NIL ↔ uuid 全零校验。

## Parity 状态

等价（UUID/站点标识字节级对齐）。

## 验证

- `d02-note-identity.mjs`：18/18 通过。
- 全量 Replay 与双 HAP 构建见 Phase 884 提交。
