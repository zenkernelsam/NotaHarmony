# Phase 961 报告 — `ree` 总入口 + 配套

## 范围

ree.java + rgc/pce/mx7。纯审计。

## 原版发现

- `ree.b` = 序列化总入口：池化 builder→IdentityHashMap 分派
  →finish→bytes。
- `rgc.b` = 未注册类型 ISE "data loss" 护栏（fail-loud）。
- `pce` = SynchronizedLazyImpl；`mx7` = MapBuilder（结构表
  用 equals 语义，表注册表用 identity）。

## 产出

- 证据：`phase-961-ree-entry-mx7.md`
- Fixture：`d02-ree-entry-mx7.mjs`（16/16）
- ADR-0905；全量 Replay 834 文件绿。
