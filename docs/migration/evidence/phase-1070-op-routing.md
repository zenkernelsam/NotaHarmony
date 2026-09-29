# Phase 1070 证据 — fsi 操作→实体 id 路由 + 删除枚举

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `fsi.F(uq9)` = 受影响实体 id 解析器

```java
switch (op.m().ordinal()):
  大多数 → hw3.I            // 空（无新实体）
  case 3,5,15,18,20,22:     // CREATE_*
      非 CREATE_PAGE → [o09(op.l())]        // 单实体 id
      CREATE_PAGE   → for i in 0..pageCount-1:
          r09(nti.g(op.l(), i))            // 页 id 区间!
```

- `o09`/`r09` = 实体/页 id 包装。
- `nti.g(opId, i)` = opId+序号合成页 id（多页 CREATE_PAGE
  一次产出连续页 id）。
- `zq9.a`/`z5c.x` 解 payload；`ln2.m()` = pageCount。

## `fsi.G/H(uq9)` = DELETE_ENTITIES 专用

```java
if (yq9.a[op.m().ordinal()] == 1):   // 仅 DELETE_ENTITIES
    G → lv2.I((s83)payload)          // 删除实体列表
    H → icj.b((s83)payload)          // 另一列表（类型分组）
else → hw3.I
```

## `fsi.J(uq9)` = serverTime ?: clientTime（Phase 1063 已录）

## Harmony 决策

- op→实体 id 路由原样：CREATE 产 id、DELETE 列 id、其余空。
- CREATE_PAGE 区间产 id 保留 `nti.g` 合成。

## 产出

- fixture `d02-op-routing.mjs`（10 断言）。
- ADR-1014；中文报告。
