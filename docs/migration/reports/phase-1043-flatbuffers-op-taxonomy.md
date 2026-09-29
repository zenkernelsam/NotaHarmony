# Phase 1043 报告 — FlatBuffers 基类与操作类型全集

## 范围

`cee`/`xwd` 基类分裂、`haa` 32 操作枚举、`ye9`/`ka4`/`exc` 接口层。
纯审计。

## 原版发现

- `cee` = Table 基类（vtable 间接 + 内联 UTF-8 解码器）；
  `xwd` = Struct 基类（固定布局）——FlatBuffers 两读取模型。
- `haa` = **操作类型全集 32 值**（byte 0–31）：页面/录音/文本/
  样式/墨迹/形状/组/块/位置/删除/瞬态/PDF 字段/复选框/peer/
  评论，外加 NONE 与 SET_METADATA、ASSET_CLOUD_PERSISTED。
- `exc.A0` = pageId 排序：a1 → (m&0xffff) → C 三键字典序。
- `ye9` 6 访问器证实 Phase 1039 ze9 映射；`ka4` = String a()。

## Harmony 决策

OpType 32 值 wire 对齐；Table/Struct 双读模型与 pageId 三键
排序保留。

## 产出

- 证据：`phase-1043-flatbuffers-op-taxonomy.md`
- Fixture：`d02-flatbuffers-op-taxonomy.mjs`（12/12）
- ADR-0987；全量 Replay 见本提交。
