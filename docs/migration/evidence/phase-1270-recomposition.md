# Phase 1270 证据 — uz4/r42/sh8/fsi Compose 重组引擎（里程碑）

来源：`defpackage/{uz4,r42,sh8,fsi}.java`。

## `uz4 implements t42` = Compose `Composer`

```java
uz4 implements t42 {   // t42 = Composer iface
    int A, B; boolean C;
    tz4 D;               // SlotTable
    ArrayList E;         // pending changes
    kgd G; lgd H; ogd I; // slot reader/writer/changes
    oha K;               // remember-observer holder
    // g0(key) 组开始 / S() 读槽 / p0 写槽 / ...
}
```

## `r42` = Composer sentinel 持有者

`static sh8 a = new sh8(20)` —— **`Composer.Empty`**
哨兵（`remember`"未初始化"标记：`objS == sh8Var`
→ 首次计算）。

## `sh8` = 共享哨兵多例

`implements 14 ifaces` + `J`-`T` + `new sh8(1..20)` —
— Compose 各处复用的 `Empty`/marker 单例族
（`r42.a`=sh8(20) 是 Composer.Empty）。

## `fsi` = 合并静态助手类

`A(Context)→Activity`、`B/C/…` + **`fsi.T(...)=remember`**
（`PointerInputEventHandler` 相关）—— R8 把 Compose
顶层函数合并进 `fsi`。

## 语义

`uz4`(Composer)+`r42.a`(Empty 哨兵)+`fsi.T`(remember)+
`tz4/kgd/lgd/ogd/oha`(slot-table) = **Compose 重组核心**
—— 槽表记录组合、`remember` 缓存、`Empty` 哨兵判
首次 —— 编辑器 UI 的声明式重组引擎。

## Harmony 决策

Composer/remember → Harmony `@Component`+`@State`/
`@LocalStorageProp`+`@Builder` —— 声明式重组语义保真
（`remember`→组件成员缓存）。

## 产出

- fixture `d02-recomposition.mjs`（10 断言）。
- ADR-1214；中文报告。
