# 原版证据：套索/矩形完成的最小尺寸门（uw2 case1，20dp/zoom）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 598 依据。

## 1. 完成判定（`uw2.java` case1）

选区手势完成时，`oo3`（选区手势状态）产出绘制区域 `cmb`：

```java
float fK = ((i3a) obj2).k();              // 当前 zoom
cmb cmbVarA = oo3Var.a();                  // 绘制区域 bounds
float f3 = 20.0f / fK;                     // 最小边长（画布单位）
if (Float.compare(cmbVarA.c - cmbVarA.a, f3) <= 0 ||
    Float.compare(cmbVarA.d - cmbVarA.b, f3) <= 0) {
    fvbVar.a();                            // 任一边 ≤ 20dp/zoom → 取消
} else if (z) {
    fvbVar.b(cmbVarA);                     // 套索提交
} else {
    // Path.addRect → fu1.b 矩形命中 → new ftc(...)  矩形提交
}
```

## 2. 语义

- `20.0f / fK`：`i3a.k()` = zoom——最小边长是 20 个屏幕 dp 折算
  到画布单位；缩得越小，取消阈值对应的画布距离越大。
- 判定**先于** `z`（套索/矩形）分支——两种模式同约束。
- `Float.compare <= 0`：任一边**等于**阈值也取消。
- `fvbVar.a()` = 丢弃本次手势，不产生任何选区状态——
  微拖动/误触点按不会留下微小选区。

## 3. `oo3Var.a()` 返回什么

`oo3` 是选区手势会话状态，`a()` 产出 `cmb`（左/上/右/下
浮点矩形）——对矩形模式即绘制矩形，对套索模式为路径
外接矩形（判定与模式无关地统一作用）。

## 4. Harmony 侧

`selectionDrawing` 收尾直接 `finalizeSelection` 提交——无尺寸门，
任何微小拖动都会留下极小选区。本 Phase 在 `finalizeSelection`
之前加 `SelectionTool.drawnBounds()`（矩形=rect、套索=路径 bbox）
+ `20.0 / viewport.zoom` 判定 → `deselect()` 取消；
`deselect()` 同时清空 `lassoPoints`/`rect` 绘制残留。
