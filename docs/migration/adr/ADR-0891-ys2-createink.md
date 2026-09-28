# ADR-0891 — ys2 CreateInk 工厂+写器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ys2.d`=CreateInk 工厂（ByteBuffer 构建 +
  `ybg.c` 校验）；`ys2.O`=20 槽写器。
- 路径=**1 字节向量**（`D(1,len,1)+b(byte)`）；
  styleMap 经 `zwd.a` inline-struct 分发。
- 写器辅助：apb.Y/Z、nti.X、z5c.P、rz1.h0/g0、
  w71=jmf ByteBuffer 实现。

## Harmony 决策

写端对齐；路径按原始字节向量写。

## Parity 状态

等价。

## 验证

- `d02-ys2-createink.mjs`：13/13 通过。
- 全量 Replay 820 文件绿，见 Phase 947 提交。
