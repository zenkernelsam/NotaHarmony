# Phase 1010 证据 — `d6c` FTS5 引擎实现 + `b50` AppSearch

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `d6c implements clc`（room-fts5）

```java
final class d6c { klc a; String b = "room-fts5"; }
```

方法映射：

| clc | 实现 |
|-----|------|
| a | `l96.L0(db,false,true,cfc(1))` = **全清**
  （cfc = `DELETE FROM search_item`） |
| b | `wkc→glc` 逐转换（**写时折叠** `nnc.a(d)`）→
  `klc` 批量 UPSERT（`l96.J0` + `ln` λ） |
| c | `l96.J0` 集合删除 |
| d | `d(ttf,String,mlc)` = LIKE 查询（SmaliJADX 236:
  `foldedText LIKE ? ESCAPE '\'`） |
| e | `mof.a` no-op |
| f | a6c 协程（索引状态/变更） |
| g | FTS5 查询（`search_fts MATCH`，269 行） |
| getName | `"room-fts5"` |
| h | `l96.L0(db,true,false,zec(13))` =
  `SELECT COUNT(*) FROM search_item` 健康计数 |

- `d`(ttf?) 限定 noteId 的 LIKE 路径；`g` 全局 FTS。

## `b50 implements clc`（appsearch）

- `getName() = "appsearch"`；九方法全实现
  （SmaliJADX 体）。
- androidx.appsearch 依赖 → HarmonyOS 不可用。

## `SearchDatabase` 三段 DAO

`u()`→oa4、`v()`→oy5、`w()`→ty5：分别为
changes/title/item 清写标记 DAO（Phase 1007 编排）。

## HarmonyOS 决策

- `d6c` 语义全量平移：clearAll/upsert/delete/count
  → relationalStore；查询层 LIKE-only（ADR-0952）。
- `b50` fail-closed。

## 产出

- fixture `d02-fts5-engine.mjs`（12 断言）。
- ADR-0954；中文报告。
