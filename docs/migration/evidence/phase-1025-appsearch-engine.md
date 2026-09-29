# Phase 1025 证据 — b50 AppSearch 引擎实现

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `b50 implements clc` = AppSearch 引擎

```java
public final class b50 implements clc {
    public final em8 b = fm8.a();   // Mutex
    public b50(f63 f63Var);          // f63=AppSearch client
    public final String getName() { return "appsearch"; }
}
```

- `f63 extends wc6` —— AppSearch session iface
  （`wc6`=appsearch 会话类型）。

## 方法形态（9 个 clc）

| 方法 | 签名 | 推断 |
|---|---|---|
| `a(ff2)` | suspend | clear-all |
| `b(List,ef2)` | suspend | 批量写入 |
| `c(Collection,ef2)` | suspend | 删除 |
| `d(ttf,String,mlc,ff2)→Serializable` | suspend | **笔记内搜索** |
| `e(ef2)`/`f(ff2)` | suspend | 初始化/flush |
| `g(String,mlc,ff2)` | suspend | **全局搜索** |
| `h(lb9)` | suspend | 状态/统计 |
| `i(String,ff2)→Serializable` | suspend | 高亮/详情 |
| `j(ff2)` | suspend | 关闭 |

## 与 `d6c`（room-fts5）对比

| | b50 | d6c |
|---|---|---|
| `getName` | `"appsearch"` | `"room-fts5"` |
| 后端 | androidx AppSearch | Room FTS5 |
| `mlc` 模式 | 直传 | 经 e6c.b 转 MATCH |

## HarmonyOS 决策

- AppSearch 是 **GMS/Jetpack 依赖**——HarmonyOS
  **不可用**；fail-closed。
- 活动引擎默认 `"appsearch"`——Harmony 侧改为
  `"room-fts5"`（唯一可用后端）；
  引擎切换 prefs 键保留（search_engine/active_engine）。

## 产出

- fixture `d02-appsearch-engine.mjs`（10 断言）。
- ADR-0969；中文报告。
