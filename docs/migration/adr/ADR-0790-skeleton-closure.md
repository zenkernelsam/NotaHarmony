# ADR-0790 — 非混淆包骨架最终闭合

- 状态：已接受（闭合声明）
- 证据：`docs/migration/evidence/phase-846-skeleton-closure.md`
- 回放：`docs/migration/replays/d02-skeleton-closure.mjs`（11/11）

## 决定

1. **宣告 `com.gingerlabs.notability` 非混淆类层完整闭合**：
   162 个 `.java` 文件按异常 64 / Worker+Init 21 / 组件 19 /
   数据库 26 / 字母模型 24 / 具名余项 8 完备分域，全部可归因
   到相位与决定（回放断言分域计数防止回归漂移）。
2. AppSearch `SearchResult` 文档（text+pageId+内置
   id/namespace/score，score 非负）登记；Harmony `search_item`
   RDB 表为更丰富的等价承载（类型枚举+rects），视为覆盖。
3. 混淆字母尾 24 类按宿主域归口（Zendesk 模型→843、
   maintenance 适配器→845、其余→本相位登记），不作语义虚构。
4. 后续审计面转向：`defpackage` 混淆语义层（如收益明确）、
   资源面残余、或 Harmony 自审。

## 后果

`decompiled_1.4.2` app 包名的静态结构审计达到**完备覆盖**；
剩余价值在运行时行为验证（受限于无设备门禁）与混淆层
语义恢复（成本/收益比高）。
