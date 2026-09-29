# Phase 1021 证据 — hl3 DraftNote DAO + vs4 日志 + jl3 修正

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hl3` = **DraftNote DAO**（修正 Phase 1018）

```java
public final class hl3 {
    public final x5c a;             // Room db
    public final sh8 c = new sh8(22);
    public final wp1 b = new wp1(this, 3);  // insert binder
    public hl3(x5c);
    public final Object a(Collection, ff2);  // 批量
}
```

- SQL：`DELETE FROM DraftNote WHERE noteId IN (...)`——
  批量删除；`a(Collection)`=批量读/写。
- `jl3.b()→hl3`——`jl3` 是 **DraftNote 仓储**（
  {pce×2, sfb, cx6} 包住 DAO），不是"连接状态 Flow"。

## `vs4` = 日志/状态 helper

```java
public final class vs4 {
    public final v7d a;      // telemetry sink
    public final sfb b;
    public final void a(String str) {
        // ep7 + yn7.LOGIN + xn7 → 登录事件日志
    }
}
```

- `a(String)` 发 `yn7.LOGIN` 遥测事件——
  ssf 鉴权调用时记录登录。

## `q75` = {vs4, dt4, cx6} 服务

- 包 vs4（日志）+dt4+cx6——可能是鉴权上层
  （ssf.a = q75）。

## `cx6` = 检查接口

- `boolean a(` + `Object getValue(`——特性/连接
  检查 iface。

## 修正记录

| Phase 1018 说 | 实为 |
|---|---|
| `jl3` = 连接状态 Flow | **`jl3` = DraftNote 仓储**
  （hl3 DAO） |
| `vs4` = 字符串 setter | **`vs4` = 遥测 logger**
  （LOGIN） |

## HarmonyOS 决策

- `jl3`/`hl3` → DraftNote Room 等价物（已建表）；
- `vs4` → Harmony 遥测点位（登录事件）。

## 产出

- fixture `d02-draftnote-repo.mjs`（10 断言）。
- ADR-0965；中文报告。
