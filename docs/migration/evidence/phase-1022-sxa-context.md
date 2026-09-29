# Phase 1022 证据 — sxa Context 持有器 + hl3 读侧

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `sxa` = Context-only 占位持有器

```java
public final class sxa {
    public final Context a;          // 唯一字段
    public sxa(Context context) { this.a = context; }
}
```

- **无方法**——纯 Context 包装；实际使用经 Kotlin
  扩展函数（decompiled 中不显现为类方法）。
- nr1 持 `sxa` 供 Context 相关检测（推断：
  ConnectivityManager/系统服务检查在 Kotlin
  `sxa.a.xxx` 扩展中）。

## `hl3` 只有读/删侧（修正补记）

- `DELETE FROM DraftNote WHERE noteId IN (...)`——
  `a(Collection)` 批量删除。
- **`INSERT` 不在 hl3**——`wp1(this,3)` binder 的 SQL
  在别处（DraftNote 的插入绑定器与 hl3 分离；
  读/删与写分离是 Room 的常见 DAO 划分）。

## `cx6` 复用确认

- `boolean a(`/`Object getValue(`——检查/取值
  接口（q75/jl3/ssf 均依赖）。

## HarmonyOS 决策

- `sxa` → ArkUI `getContext()` 等价；系统服务检测
  用 `@kit.NetworkKit`/`@kit.BasicServicesKit`。
- DraftNote 读删与写分离保留。

## 产出

- fixture `d02-sxa-context.mjs`（10 断言）。
- ADR-0966；中文报告。
