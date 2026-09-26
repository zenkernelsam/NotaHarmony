# ADR-0708 — 原版 1.4.2 版本差异登记与处置范围

日期：2026-09-29
状态：已登记（版本差异处置范围；不引入 Harmony 源码变更）
证据：`docs/migration/evidence/original-1.4.2-decompile-version-delta.md`

## 背景

用户预下载的原版 `Notability_1.4.2` xapk（versionCode 1040002）此前从未反编译，
`decompiled_1.4.2/` 为空目录。交接文档（SWE2-2026-09-21）P3 段明确规定：
1.0.3 剩余 TODO（P1）收敛后，可对 1.4.2 执行与 1.0.3 相同方法的反编译与
diff 初筛，作为独立 Phase 插入；其产出是 T-042（Goal 最后一项）的直接输入。

1.0.3 静态审计面已收敛（全部已探面落地为"已移植/已登记 fail-closed/待真机"三态），
故本阶段执行 1.4.2 反编译与版本差异初筛。

## 决策

1. **版本基线不变**：NotaHarmony 移植基线仍为原版 1.0.3（versionCode 1014）。
   1.4.2 新增功能不自动进入移植范围，先登记为"版本差项"。
2. **fail-closed 框架顺延**：1.4.2 新增簇中属私有后端/账号/商店/远端服务者
   （Gallery 社区、贴纸商店、模板云同步、远端 HWR `HwrEngineService`、
   Passkey/SSO、笔记上限付费墙、课程表服务端解析、Demo/维护 Worker），
   沿用既有 ADR-0657~0659 同类处置，登记为版本差 fail-closed 边界，
   不伪造 Harmony 等价物。
3. **本地候选待审**：自定义模板本地 CRUD（`ui_templates__*` 本地部分）、
   闪卡导入自定义分隔符、系统日历连接（Harmony Calendar Kit 另行评估）、
   `save_as_sticker` 自制贴纸等登记为"版本差·待审"项；是否回移 1.4.2
   行为由后续独立 Phase 逐簇判定，本 ADR 不作逐类移植承诺。
4. **移除面登记**：AppSearch 引擎重构（`data/search` → `data/search/engine/appsearch`）
   与 36 个 `feature_*` 键移除列入 T-042 版本差异输入，不视为功能删除。

## 后果

- `decompiled_1.4.2/` 成为与 `decompiled_1.0.3/` 并列的只读证据树；
  Replay fixture `d02-original-1.4.2-version-delta.mjs` 钉住指纹与标志类存在性。
- 后续 Phase 若要采纳 1.4.2 行为，须引用本 ADR 并给出 1.0.3/1.4.2 双侧证据。
- T-042 最终版本差异文档以本阶段 diff 数据 + 后续逐簇复核为输入。
