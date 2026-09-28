# Phase 971 报告 — dbj.c 字符串写器双路径

## 范围

dbj/v71/com.google.flatbuffers.a。纯审计。

## 原版发现

- `dbj.c`：普通串走 `a.l` UTF-8 编码；`v71`（原生
  UTF-8 字节视图，subSequence 禁用）走 `sg5.b` 池化
  缓冲 + `a.m` byte-vector 零拷贝直通。
- `a.m` 细节：NUL + D(1,len,1) + put + o()。

## 产出

- 证据：`phase-971-string-writer.md`
- Fixture：`d02-string-writer.mjs`（15/15）
- ADR-0915；全量 Replay 见本提交。
