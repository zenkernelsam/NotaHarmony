# Phase 1007 证据 — 搜索编排器（vmc + clc 接口 + SearchDatabase 三段 DAO）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `clc` = SearchEngine 接口（9 方法）

```java
interface clc {
    Object a(ff2);                       // init/prepare
    Object b(List, ef2);                 // 批量建索引
    Object c(Collection, ef2);           // 删除项
    Serializable d(ttf, String, mlc, ff2); // 查询(noteId?,query,参数)
    Object e(ef2);
    Object f(ff2);
    Object g(String, mlc, ff2);          // 查询变体
    String getName();                    // "room-fts5"/"appsearch"
    Object h(lb9);                       // 变更回流?
}
```

- 实现：`d6c`（room-fts5）+ `b50`（appsearch）。
- `mlc`/`lb9` = 查询参数/结果类型。

## `vmc` = 编排器（13 deps）

```java
vmc(Context, clc engine, id7, ya9, jc5, zb5, p29,
    c33, dm9, rx9, s33, SearchDatabase, j4e)
```

- `p = searchDatabase.w()` → `ty5`；
  `q = v()` → `oy5`；`r = u()` → `oa4`
  —— **三段 DAO**（清除/写入/标记，待考各表归属）。
- `hmc` = 三段 rebuild 协程：`p.a → q.a → r.a`
  顺序挂起（clear→fill→complete 推断）。
- 引擎切换：`SharedPreferences("search_engine")`
  `active_engine` 默认 `"appsearch"`；不同→
  `clc.a` 初始化 + 重建遥测（Phase 1003）。

## `hmc` rebuild 顺序（invokeSuspend case 0）

```
ty5 p .a()   →  oy5 q .a()   →  oa4 r .a()
（deleteAll?   →  bulkIndex?   →  markDone?）
```

## AppSearch 引擎（`b50`）

- `androidx.appsearch` 依赖（GMS/Jetpack 库）。
- HarmonyOS 无对应 → fail-closed。

## HarmonyOS 决策

- `clc` 契约可平移：ArkTS `SearchEngine` 接口 +
  单实现（relationalStore LIKE 路径，ADR-0947）。
- 引擎切换/SharedPreferences 不再需要 —— Harmony 仅
  单引擎，`vmc` 退化为直接注入。

## 产出

- fixture `d02-search-orchestrator.mjs`（12 断言）。
- ADR-0951；中文报告。
