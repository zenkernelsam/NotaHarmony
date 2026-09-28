# ADR-0893 — z0c 全量写端注册表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`z0c`=80 项写端注册表（15 xwd 结构 + 65 cee
表）；`zwd.a` KClass 键分发 + 未知类型
`rgc.b` 硬抛。写器实现：qee 参数化 +
ywd/pee 匿名 wx4。
**b3d SetWritingDirection 无独立写器**——
由 he8 内嵌写（setter 注册唯一缺席）。

## Harmony 决策

写端注册=读端 zq9 的镜像核对表；
b3d 缺席语义保留。

## Parity 状态

等价（zq9↔z0c 双注册表闭环）。

## 验证

- `d02-z0c-registry.mjs`：87/87 通过。
- 全量 Replay 822 文件绿，见 Phase 949 提交。
