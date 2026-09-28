# Phase 947 报告 — ys2 CreateInk 工厂+写器

## 范围

最大 ink 写端链钉死。纯审计。

## 原版发现

- ys2.d=工厂（构建+ybg.c 校验）；ys2.O=20 槽
  写器，f0-f19 与 909 读端镜像。
- 路径向量终证=原始字节（1B 元素）；
  styleMap 经 zwd.a 结构分发。
- 写器辅助全登记。

## 产出

- 证据：`phase-947-ys2-createink.md`
- Fixture：`d02-ys2-createink.mjs`（13/13）
- ADR-0891；全量 Replay 820 文件绿。
