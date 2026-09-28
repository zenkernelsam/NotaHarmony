# ADR-0901 — `nti` 线协议助手 + LEB128 编码对

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `X` = cxc 12B 写器（与 `sg5.f` 字节一致）；`f`=cxc 工厂
  （site,ts,idx）；`g`=`f(qo5.site,qo5.ts,idx)`——**SeqId = 实体
  Id + 段内 index 的派生**。
- `n0` = u32 LEB128；`o0` = i32 zigzag-LEB128——唯一调用点
  `iy0.a` = `bk_paths.append` 自研路径 blob 编解码（varint 计数 +
  2bit 标志打包 + zigzag 增量量化 ×4096 + CRC32 + 索引/数据双文件）。
- `p` = 范围检查 helper。

## Harmony 决策

- cxc 写/工厂等价（Replay 覆盖）。
- LEB128 磁盘日志编码非 FlatBuffer——Harmony 若保同格式存储
  需复刻（Phase 958 详表 bk_paths 格式）。

## Parity 状态

线协议等价；磁盘编码为待对齐存储格式。

## 验证

- `d02-nti-wire-helpers.mjs`：19/19 通过。
- 全量 Replay 830 文件绿，见 Phase 957 提交。
