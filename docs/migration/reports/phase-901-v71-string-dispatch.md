# Phase 901 报告 — `dbj.c`/`v71` 字符串写路径实名

## 范围

实名所有表字符串字段的写派发与原始字节视图。纯审计。

## 原版发现

- `dbj.c`：v71 → builder.m 原始字节写；否则 builder.l
  createString；sg5.b ThreadLocal 暂存。
- `v71` = ByteBufferBackedCharSequence：char 访问抛错，
  仅整块 UTF-8 拷贝 → **字节精确往返契约**。
- builder l=createString/m=raw bytes 原语实名。

## Harmony 核对

须保留接收字符串 byte 级透传（reader→encoder 通路）。

## 产出

- 证据：`phase-901-v71-string-dispatch.md`
- Fixture：`d02-v71-string-dispatch.mjs`（12/12）
- ADR-0845；全量 Replay 774 文件绿。
