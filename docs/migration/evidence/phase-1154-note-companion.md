# Phase 1154 证据 — x09 标记接口 + m09 笔记伴生

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `x09` = 笔记聚合标记接口

`a79 implements x09` —— 单字段 `{static m09 a = m09.a}`
伴生，无方法（实体聚合的种类标签）。

## `m09` = 笔记伴生/默认值

```java
static m09 a;
qed b;      // scale 默认
double c;   // 参
vy7 d;      // margins 默认
hu1 e; nz9 f; float g
static { b=a79.N; d=a79.O; g=a79.P; … }   // 镜 a79 默认
static Object a(r29, cl9)                  // 工厂
```

`m09` 镜 `a79` 的静态默认（`N`=scale、`O`=margins、
`P`=param）+ `a(r29,cl9)` 工厂 —— note 聚合的伴生对象。

## 语义

- `x09` = 标记 iface：标 `a79` 为"笔记聚合"种类
  （同 `x09.a` companion）。
- `m09` = 伴生：暴露 `a79.N/O/P` 默认值 +
  `a(bundle, ctx)` 工厂 —— note 的默认/构造入口。

## Harmony 决策

- 笔记聚合标记 = 种类接口；伴生 = 默认值集 + 工厂。
- Harmony：note defaults 常量 + `create(bundle,ctx)`。

## 产出

- fixture `d02-note-companion.mjs`（10 断言）。
- ADR-1098；中文报告。
