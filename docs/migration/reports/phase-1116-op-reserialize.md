# Phase 1116 报告 — op 重序列化 + v71 零拷贝

## 完成内容

- `kci.j(f46,a)` = op 表复制/重写。
- `dbj.c` = createString + `v71` ByteBuffer-backed CharSequence。
- `sg5.b` thread-local scratch。

## 产出

- evidence `phase-1116-op-reserialize.md`
- fixture `d02-op-reserialize.mjs`（10/10）
- ADR-1060
