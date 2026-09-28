# Phase 957 报告 — `nti` 线协议助手

## 范围

nti.java 序列化成员 + iy0.java 预读。纯审计。

## 原版发现

- `X/f/g` = cxc 写器+工厂对+Id→SeqId 派生（qo5+index）。
- `n0/o0` = LEB128/zigzag-LEB128 变长编码——`bk_paths.append`
  自研 blob 编解码核心（非 FlatBuffer）。
- `iy0` = 笔迹日志追加器：varint 计数、2bit 标志打包、
  zigzag 增量 ×4096 量化、CRC32、索引/数据分离双文件、mmap 读。
- `p` = 范围检查。

## 产出

- 证据：`phase-957-nti-wire-helpers.md`
- Fixture：`d02-nti-wire-helpers.mjs`（19/19）
- ADR-0901；全量 Replay 830 文件绿。
