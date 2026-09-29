# Phase 1018 证据 — nr1 依赖名册（ssf/qr1/jl3/sxa）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 依赖

| dep | 结构 | 推断角色 |
|---|---|---|
| `ssf` | {q75, xrf, vs4, pce} | 同步协调/网络门 |
| `qr1` | {pce a, pce b} + `a()→File`,`b()→File` | **懒 File 提供器**——
  笔记文件目录+缓存目录 |
| `jl3` | {pce a, pce b, sfb c} + `cx6` | 连接状态
  Flow 提供器（`b()→hl3`） |
| `sxa` | {Context} | 系统服务 wrapper
  （connectivity 检测推断） |
| `v2f` | `{t2f a()}`（Phase 1000） | 时钟 |

## `qr1` 懒 File

```java
public final File a() {  // a=pce lazy
    return (File) this.a.getValue();  // files dir?
}
public final File b() { ... }         // b=pce lazy  // cache dir?
```

- 双 `pce` 惰性 File getter——笔记存储目录 +
  临时/缓存目录。

## `jl3` = 连接状态 Flow 持有

- `sfb c` = 持有型 Flow（连接状态 Flow）
- `b() → hl3` 返回连接状态对象
- `cx6` 依赖（连接仓储）

## `sxa` = Context-only

- 单 `Context` 字段——系统服务访问 wrapper
  （最可能 ConnectivityManager / 电池状态）。

## HarmonyOS 决策

- `qr1` → `context.filesDir`/`cacheDir` 等价
  （ArkUI context API）。
- `jl3`/`sxa` → Harmony `connection` 模块
  （`@kit.NetworkKit`）连接状态监听。
- `ssf` 内部结构在后续 phase 展开。

## 产出

- fixture `d02-nr1-deps.mjs`（10 断言）。
- ADR-0962；中文报告。
