# Phase 1082 证据 — do6.i 页裁剪查找 + nti.y 时间戳

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `do6.i(cxc page, Map) → Object(bmb crop)`

```java
return map.get(new tz9(cxcVar));   // 裁剪表以 tz9 页引用为键
```

- 页裁剪表 `map7`（1078）的键 = `tz9{cxc}` 页引用包装；
  值 = `bmb` 裁剪矩形（Phase 1056）。

## `nti.y(uq9) → xgb?` = op 服务端时间戳

```java
tmf j = op.j();                    // serverTime (ULong, 可空)
return j != null ? new xgb(j.I) : null;
```

- `xgb` = 时间戳值类（寄存器 `c` 字段类型，Phase 1063）。
- `fsi.J`（serverTime ?: clientTime）与 `nti.y`（仅
  serverTime，可空）分工：前者兜底、后者严格。

## `do6` = 工具 mega-merge（字符串助手 j/k/l/m 等）

## Harmony 决策

- 页裁剪以 `tz9` 键索引；`nti.y` 严格服务端时间（可空）。

## 产出

- fixture `d02-crop-timestamp.mjs`（10 断言）。
- ADR-1026；中文报告。
