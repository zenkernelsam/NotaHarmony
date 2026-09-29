# Phase 1074 证据 — ie8 变换项 + yy3/xy3 快照-构建器环

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ie8 extends cee implements ka4` = 变换项（ModifyPositions 元素）

| 访问器 | 类型 | 语义 |
|--------|------|------|
| `j()` | `fqa` | origin |
| `k()` | `cxc` | 页 id |
| `l()` | `k2d` | scale 包装 |
| `m()` | `y2d` | rotation 包装 |
| `n()` | `qo5` | 实体 id |
| `o()` | `tmf` | zIndex（ULong） |

`a()→ddg.e(this)` 校验委托给 `ddg`（Phase 1046 中央校验库）。

## `yy3 extends ly3, qg2` = 实体快照接口

```java
int E();
xy3 builder();        // 快照→构建器（环）
```

- `xy3.build()→yy3`、`yy3.builder()→xy3` —— 快照/构建器
  双向环（不可变快照 ↔ 可编辑）。
- `qg2`/`ly3` = 快照基接口。

## `v69` 物化路径闭环

`xy3.build()→yy3` 存进 `v()` 不变表（positionLocked 分支）。

## Harmony 决策

- `ie8` 变换项六元组原样；校验走 `ddg.e`。
- 实体快照=不可变 `yy3`，`builder()` 复原可编辑 `xy3`。

## 产出

- fixture `d02-transform-item.mjs`（10 断言）。
- ADR-1018；中文报告。
