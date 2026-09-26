# ADR-0750：原版依赖版本升档登记（工具链谱系证据）

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-806-dependency-bumps.md`
- Replay：`docs/migration/replays/d02-dependency-bumps.mjs`

## 决定

将 1.0.3→1.4.2 的 66 项依赖版本升档登记为工具链谱系证据；
不作为 Harmony 移植输入（全部为 AndroidX/KotlinX 框架件）。

## 依据

- Compose BOM 1.11.2→1.12.0（13 模块）、M3-adaptive
  alpha09→stable、lifecycle beta02→stable——原版工具链持续
  跟车并与 1.4.2 UI 面增量配套。
- ink 引擎 alpha04→alpha07 + ink-storage 新增（Phase 776/798
  闭环）。
- Room 2.8.4 持平——Phase 767 的表增量确认为应用 schema
  演进，非库强制迁移。
- transition 1.6.0→1.5.0 为版本体系换算而非回降。

## 影响

依赖谱系证据完整，作为 T-042 工具链章节输入；
Harmony 无对应移植动作。
