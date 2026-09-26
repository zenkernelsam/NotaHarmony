# Phase 806 报告：依赖版本升档清单

日期：2026-09-23
Phase 类型：证据登记（无代码改动）

## 摘要

解析两版全部 `META-INF/*.version` 内容，得到 66 项依赖版本升档的
完整清单（129→130 个 versioned artifact，唯一新增为已登记的
ink-storage）。

## 主要升档

- **Compose BOM 1.11.2→1.12.0**（ui/runtime/foundation/animation 等
  13 模块）——原版跟车 Compose 发布线
- **M3 Adaptive alpha09→1.3.0 stable**、**Lifecycle beta02→2.11.0
  stable**——两个全家桶随 1.4.2 毕业
- **Ink 引擎 alpha04→alpha07**（6 模块）+ storage 新增
- Navigation 2.9.7→2.10.0、Navigation3 1.1.0→1.1.7、
  Coroutines 1.10.2→1.11.0、core 1.18→1.19、tracing 1.3→2.0.1 等

## 持平锚点

Room runtime 2.8.4 持平——证明 Phase 767 的 21 张新表为应用 schema
演进而非库迁移。

## 验证

- `d02-dependency-bumps.mjs`：6/6 green
- 全量套件与双 HAP：见提交

## 产物

- 证据：`docs/migration/evidence/phase-806-dependency-bumps.md`
- Replay：`docs/migration/replays/d02-dependency-bumps.mjs`
- ADR：`docs/migration/adr/ADR-0750-dependency-bumps.md`
