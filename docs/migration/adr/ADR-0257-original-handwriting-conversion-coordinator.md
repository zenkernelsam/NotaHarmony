# ADR-0257：原版手写转文字生产编排与统一结果门禁

- 状态：Accepted（Phase 279，2026-08-22）
- 范围：原版 1.0.3 Convert-to-Text 的 caller/coordinator 边界
- 相关：ADR-0254（planner）、ADR-0255（atomic persistence/history）、ADR-0256（context/provider capability）

## 决策

新增纯编排模块 `OriginalHandwritingConversionCoordinator.ets`，但暂不增加产品菜单或伪造 OCR
provider。模块通过注入的 context reader、freshness reader、recognition provider 和 persistence gateway
串联既有边界，并返回结构化 outcome。

唯一允许的成功路径是：

```text
page snapshot → selection adapter → planner → context → provider
→ page/generation/fingerprint freshness check → atomic persistence
```

## 不变量

1. `acceptedStrokeIds` 是 planner、recognizer 和 persistence 的唯一源序列；不得在任一层重新从 UI
   selection 猜测或排序。
2. OCR 请求发出前冻结 exact `StrokeElementData` persisted snapshot；迟到结果必须重新读 freshness
   三元组。
3. coordinator 在调用 context/provider 前要求全部 source ID 可解码为 canonical `op:*` identity；`nb-*`
   等导入 ID 仍可用于纯 selection/provider adapter，但不能进入只接受原版 entity identity 的 type-25 写回。
4. `commitOriginalHandwritingConversion()` 独占 original operation identities、DELETE/CREATE/INSERT
   transaction 和历史 companion；coordinator 不预造 Text ID。
5. 失败只返回 outcome，不修改 selection、画布、history stack 或页面内容。
6. provider 结果必须通过同一个 UTF-8/Unicode/1 MiB 门禁；空白结果按原版 `lvd.E0/cq.f0` 拒绝，合法
   前后空白不 trim。

## 结果分类

| 类别 | outcome |
|---|---|
| 请求/计划 | `INVALID_REQUEST`, `PLAN_REJECTED`, `SOURCE_IDENTITY_UNSUPPORTED` |
| provider/context | `PROVIDER_UNAVAILABLE`, `CONTEXT_FAILURE`, `PROVIDER_FAILURE`, `PROVIDER_NO_RESULT` |
| 迟到/非法结果 | `RESULT_REJECTED`, `STALE_RESULT`, `FRESHNESS_FAILURE` |
| 写回 | `PERSISTENCE_FAILURE`, `SUCCESS` |

## 原版依据

- `dhb.java` 先过滤 eligible Ink 并创建 ID 快照；`hc5.java` 空列表不调用识别。
- `tsc.java` 用 `lvd.E0` 判断全空白；`re0.java` 在转换完成后记录历史。
- `bt1.java` 在单一 transaction 内按 DELETE → CREATE → INSERT 排序。

哈希、行号和限制见：
`docs/migration/evidence/original-handwriting-conversion-coordinator-jadx-2026-08-22.md`。

## UTF-8 门禁决策

过去 planner 以 `result.text.length`（UTF-16 code unit）判断 1 MiB，和实际
`OriginalInsertTextPayloadEncoder` 的字节预算不一致。本阶段新增
`OriginalHandwritingConversionTextPolicy.ets` 与导出的
`inspectOriginalInsertStringValue()`，统一检查：严格 UTF-8 round-trip、1 MiB byte limit、空字符串、
全空白和孤立 surrogate。分类顺序保留原版状态机语义：非空后先判断全空白，再应用 Harmony wire 的
Unicode/byte 限制；因此超大纯空白仍报告 `RESULT_WHITESPACE_ONLY`。持久化层继续做最终防线。

## 未决事项

- 真正 stroke-native OCR provider、完整语言覆盖、UI 入口和设备体验仍未完成。
- 页面 fingerprint 的生产采集仍由未来 caller 提供；本 ADR 不把静态 fixture 当运行态接入。
- `T-042` APK 版本追踪严格留到 Goal 最后一项。
