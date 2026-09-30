# Phase 1219 证据 — ype = 布局几何持有（wpe + mv6×4 + q21 回调）

来源：`defpackage/{ype,q21,r21}.java`。

## `ype` = 文本域布局坐标持有

```java
yme a = yme b;          // 文本布局态（c()→wpe）
p6a c,d,e,f;            // LayoutCoordinates 态×4
q21 g = new q21();      // r21[16] 回调队列
```

## API

- `a(long)→cmb` = 视口可见矩形裁剪（`mv6.J`）。
- `b()→mv6` = 内部 LayoutCoordinates。
- `c()→wpe` = 当前文本布局（经 `yme`）。
- `d(long,bool)→int` = **位置→偏移**（`wpe.b.j(
  zii.f(this,j))` 坐标转文本偏移——命中测试）。
- `e()→mv6` = 外部/装饰 LayoutCoordinates。
- `f(long)→bool` = 界内判定。

## `q21` = 布局回调队列

`{ql8 a = new ql8(0, r21[16])}` —— 16 槽 `r21` 监听器
数组（`p21.O & 0x80000000` 标志位分发）——
`onTextLayout` 回调容器。

## 判定

`ype` = 编辑器几何提供层：`wpe` 文本布局 + 4 个
`LayoutCoordinates`（内/外/装饰/容器）+ 位置→偏移
命中测试 + 布局回调 —— 对齐 Compose `TextFieldDelegate`
的布局追踪。

## Harmony 决策

`ype` → Harmony 布局坐标持有组件（`componentUtils`
取矩形 + 文本命中偏移 + `onAreaChange` 回调列表）。

## 产出

- fixture `d02-ype-layout-holder.mjs`（10 断言）。
- ADR-1163；中文报告。
