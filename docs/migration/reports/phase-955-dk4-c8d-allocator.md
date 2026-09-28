# Phase 955 报告 — `dk4`/`c8d` builder 池与分配器

## 范围

dk4.java + c8d.java + k1a/ck4/ldj。纯审计。

## 原版发现

- `dk4.a` = 池化 builder 工厂（cz8 池 + clear 复位）。
- `c8d` = SharedMemory("fbb-shm") 分配器——原版笔记
  FlatBuffer 直接构建于 ashmem 段，k1a 追踪 unmap。
- 分配器属内存管理，非线格式；Harmony 用普通缓冲等价。

## 产出

- 证据：`phase-955-dk4-c8d-allocator.md`
- Fixture：`d02-dk4-c8d-allocator.mjs`（12/12）
- ADR-0899；全量 Replay 828 文件绿。
