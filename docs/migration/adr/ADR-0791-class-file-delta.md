# ADR-0791 — 1.0.3→1.4.2 类文件级增量封存

- 状态：已接受（版本差分封存）
- 证据：`docs/migration/evidence/phase-847-class-file-delta.md`
- 回放：`docs/migration/replays/d02-class-file-delta.mjs`（17/17）

## 决定

1. 版本增量以**文件级** diff 封存：+42 新增、−2 移除
   （`data/search/SearchResult`×2 迁移至 `engine/appsearch`），
   净增 40 新类。补充 818 包级计数的完整名单。
2. 新增域全部映射到既有相位决定（calendar/gallery/hwr/learn/
   loginstate/notelimit/ops/templates/user/stickers/
   maintenance/infra/snapshot/backgroundwork），不产生新
   Harmony 面。
3. 回放固化完整断言集，防止后续版本资料漂移。

## 后果

1.0.3→1.4.2 的类层增量完备登记；版本追踪剩余 T-042
（按硬约束保留为最终任务）。
