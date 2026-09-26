# Phase 846 — 非混淆包骨架最终闭合 + AppSearch 文档

证据：`decompiled_1.4.2` `com.gingerlabs.notability` 全 162 个
`.java` 文件的分域盘点核对（本相位做封闭集合校验）。

## 一、162 文件完备分域

| 类别 | 数量 | 归因相位 |
|------|------|----------|
| `*Exception`/`*Error` | 64 | 840–844 |
| `*Worker`/`*Initializer` | 21 | 845（15+6） |
| 组件（Activity/Provider/Receiver/Service/NbApplication） | 19 | 824/826/829/832–837 |
| `*Database`(+`_Impl`) | 26 | 822（13 库 45 实体） |
| 混淆字母模型（a–l） | 24 | 843（Zendesk）/845（maintenance 适配器）/本相位登记为不可恢复命名 |
| 具名余项 | 8 | 见下 |

具名余项×8：`SearchResult` + `C$$__AppSearch__SearchResult`
（AppSearch 文档+生成适配器，本相位）、`R.java`、
`ForegroundReturned`（CancellationException，845 域）、
`NbPerformance$SpanAborted`（841）、`GLMathNative`/
`GLMathTextMeasurer`/`MathDrawTarget`（841）。

合计 64+21+19+26+24+8 = **162 全覆盖，零遗漏**。

## 二、AppSearch `SearchResult` 文档 schema

`@Document` 类：字段 `text` + `pageId`（String 属性）+
文档内置 `id`/`namespace`/`score`（生成适配器强制
`score ≥ 0`）。搜索结果项契约——匹配条目携带文本与
pageId 回链。

Harmony 对应：`search_item` RDB 表
（`note_id/type/sub_id/page_id/folded_text/rects`，
DatabaseHelper 注释明示镜像原版 Room 实体）——**schema
更丰富**（类型枚举 + rects 定位），AppSearch 只是其投影。

## 三、混淆字母尾 24 类处置

- `ui/support/data/a–l`：Zendesk Retrofit 模型（843 端点归口）；
- `domain/maintenance/a/b`：协程适配器（845 域）；
- `core/model/a-c`、`core/common/{logging,memory}/a`、
  `core/network/a`、`data/{learn,transcription}/a-b`、
  `hwr/myscript/a`：混淆内部类，命名不可恢复——按宿主域
  归口登记，不作语义虚构。

## 四、结论

`com.gingerlabs.notability` 非混淆类层**完整闭合**：
162/162 文件可归因到相位与决定；后续审计面转向混淆
`defpackage` 语义层（如需）或其他资料面。
