# ADR-0900 — `cee`/`xwd` 读侧原语层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `xwd` = 内联结构基类 `{I 偏移, J bb}`（无 vtable，定长直读）。
- `cee` = 表基类 `{I,K=vtableOff,L=vtableLen,J}`：
  `c(N)`=vtable 槽读（`i<L→getShort(K+i)`，0=缺省），
  `c(4+2n)`=fieldN——此前全部读侧偏移断言的根基；
  `e()`=内联 UTF-8 解码（ASCII 快路 + x82.A/z/y 多字节 +
  畸形/越界双护栏）；`f/i`=向量始/长；`g`=零拷贝 LE 切片。
- `zq6` = R8 归并多角色类；`x82` A/z/y = UTF-8 2/3/4B→UTF-16。

## Harmony 决策

Harmony 解码器已实现同构原语（Replay 覆盖）；UTF-8 代理对
语义与手动解码等价。

## Parity 状态

等价。

## 验证

- `d02-cee-xwd-primitives.mjs`：22/22 通过。
- 全量 Replay 829 文件绿，见 Phase 956 提交。
