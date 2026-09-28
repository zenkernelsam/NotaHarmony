# Phase 949 报告 — z0c 全量写端注册表

## 范围

写端 serializer 注册表完整登记。纯审计。

## 原版发现

- z0c=80 put()：mx7Var 15 xwd 结构 +
  identityHashMap 65 cee 表（全 op+信封+
  setter+形状+锚+模型）。
- zwd.a KClass 键分发+rgc.b 失败关闭。
- **b3d SetWritingDirection 缺席**——唯一
  无独立写器的 setter（he8 内嵌）。
- 新类型登记：p9/r60/yq3/q89/xq3。

## 产出

- 证据：`phase-949-z0c-registry.md`
- Fixture：`d02-z0c-registry.mjs`（87/87）
- ADR-0893；全量 Replay 822 文件绿。
