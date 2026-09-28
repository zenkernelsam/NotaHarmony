# Phase 959 — 基础设施三件：`cz8` 池、`x82.x` 委托、`m18` 集合

来源：`decompiled_1.0.3/sources/defpackage/cz8.java`、`x82.java`、
`m18.java`、`th7.java`

## 1. `cz8 extends ThreadLocal` — 复位式线程局部池

```java
{Function0 a = 工厂; ix4 b = 复位λ}
initialValue() = a.invoke();      // 线程首取 = 新建
get()          = super.get() + b.invoke(obj);  // 每次取都复位
```

**每线程单实例 + 取用即复位**——`dk4.b` 的 ByteBuffer 池
（`ck4.P`=`clear()`）、`sg5` 的持有者族全部基于此。

## 2. `x82.x(cz8, fl6)` — 属性委托 acquire

```java
Object objA = cz8.a();            // 原始 super.get()（不复位）
cz8.b.invoke(objA);               // 手动复位
return objA;
```

Kotlin `getValue(thisRef, prop)` 的编译形态——与 `cz8.get()`
等价但显式分两步。

## 3. `m18` 集合三件套（物化器核心）

- `S()` = `new th7(10)` — ListBuilder 容量 10
- `E(list)` = `th7.i()`(**checkIsMutable**) + `K=true`(**封存**) +
  `J>0 ? 自身 : th7.L`(空哨兵) — Kotlin `buildList` 尾步
- `y0(f)` = `Math.round(f)` + NaN 检查（"Cannot round NaN"）—
  bk_paths ×4096 量化用的舍入器

所有 `lv2` 物化器模式：`S()` → 逐元素 `add` → `E()` 得
不可变 List（空时共享 `th7.L`）。

## 4. `th7` = Kotlin `ListBuilder`（stdlib 内联）

`u4` 基类 + `RandomAccess` + `K`=isReadOnly 旗标 +
`L`=空密封单例 + `i()`=可变检查——Kotlin stdlib
`AbstractMutableList`/`ListBuilder` 的混淆名。

## 5. `x82.A/z/y` — UTF-8→UTF-16 手写解码（Phase 956 引用）

`y`（4 字节）实证：`((b2&7)<<18)|((b3&63)<<12)|((b4&63)<<6)|
(b5&63)` → 代理对 `(i3>>>10)+55232` / `(i3&1023)+56320`——
标准 UTF-8 4B→UTF-16 代理对公式，含 `B()` 续字节校验。

## 6. Harmony 对齐

- 池/委托：Harmony 无需 ThreadLocal 池（对象轻量 + ArkTS GC），
  等价语义但无共享可变缓冲——**更安全的默认**。
- `buildList` 语义：ArkTS 数组天然可变/冻结用 `Object.freeze`，
  Replay 断言空→共享哨兵差异无观测影响。
- `y0` 舍入 = `Math.round` 等价。

## 7. 验证

- `d02-cz8-m18-infra.mjs` 静态断言。
