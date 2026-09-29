# Phase 1086 证据 — v69 上下文依赖：ny3/al2/jm5/a79

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ny3` = 包围盒服务接口

```java
void a(qo5 id, int i, k11 bounds);   // 设实体包围（id+子序号）
k11 e(qo5 id, int i);                // 取
```

`v69.c` 持 `ny3` —— 文档根委托包围盒存储（空间索引后端）。

## `al2 implements Map,ik6` = tombstone 因果 map

```java
{gja I, Set J, bool K, Set L, bool M, a2d N}
```

`v69.j()→al2` = 删除标记表（ba6.K 查的 map）；`gja` 内层
因果集 + J/L 脏标记集 + `a2d`。

## `jm5` = 通用槽位 holder（`{int a,b; Object c..g}`）

`v69.d` —— 文档的临时/聚合状态槽。

## `a79` = 常量注册表（56 pubs，Phase 1037）

`v69.a` = 文档常量。

## Harmony 决策

- `ny3` 包围盒服务抽象（`a`/`e` set/get）。
- `al2` tombstone map（Map 接口 + 脏追踪）。

## 产出

- fixture `d02-doc-context.mjs`（10 断言）。
- ADR-1030；中文报告。
