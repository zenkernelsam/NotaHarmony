# Phase 1106 证据 — e4c.b(uq9) 文本 op 应用状态机

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e4c implements o4c` = live 文本块

```java
static qo5 q = rh8.b(-1, 0);      // 哨兵 opId{-1,0}
m4c b;                             // 块 spec
gja f;                             // 因果 store builder
al2 g;                             // tombstone map
iwc e; k4c d/o; LinkedHashMap l; …
```

## `e4c.b(uq9) → i4c` = op 分派

`uq9.m().ordinal()` 分派：

- **case 7**：`e46` → `e(e4c, cxc)` 位序 → `uwc{length, qo5, cxc,
  fsi.J(op), tmf?:op.k(), pos}` → `h4c` 包装。
- **case 8**：`f46` → `f46.g(6)` ByteBuffer → CharsetDecoder UTF-8
  （`coderResultDecode` 双循环解码）。
- `!=28` 守卫 + switch —— 文本 op 类型路由。

## `e4c.e(e4c, cxc)→Integer` = 锚点位序解析

## `e4c.h(...)` = `s3c` 样式段构建

`(exc) au1.c1(gxc)` 锚点 + `gxc.get(i)→hr5` + `s3c{set,set,mz0,double,int,exc,hr5}`。

## `e4c.A(Integer)` = tombstone 判定

`swc.d(new hr5())` 派生锚 → `xj2.f(exc, g.I)` 查 tombstone map。

## Harmony 决策

- 文本应用 = op 类型分派 + UTF-8 解码 + 锚点位序 + tombstone 判定。
- 哨兵 opId `{-1,0}` 作起始锚。

## 产出

- fixture `d02-text-apply.mjs`（10 断言）。
- ADR-1050；中文报告。
