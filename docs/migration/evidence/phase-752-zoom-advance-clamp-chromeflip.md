# Phase 752 证据：原版 Zoom 前进区宽夹取域 [48,336] + panelInTopHalf chrome 翻转

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0697（前进区宽持久化）、ADR-0698（覆盖层）。

## 1. 前进区宽夹取域修正（Phase 749 缺陷修正）

`htd.java` case 18 —— `ahg.setAdvanceRegionWidth` 委托体：

```java
float f = ((Number) obj).floatValue();
do {
  value = asd.getValue();
} while (!asd.i(value,
  ggg.a(value, false, null, 0.0f,
        rh8.u(fFloatValue, 48.0f, 336.0f),   // coerceIn(48, 336)
        false, 47)));
```

`rh8.u(v, lo, hi)` = Kotlin `coerceIn`——**原版拖拽实时夹取域为
[48dp, 336dp]**。Phase 749 Harmony 实现误用 [60, 320]（估值），
本 Phase 更正为 [48, 336]（vp 等价）。

读侧（`bc7` DataStore 读回）无夹取——与原版一致（clamping 仅存在于
setter 写入路径）。

## 2. `ggg.f` = `panelInTopHalf`（补齐第 6 状态字段）

`ggg.toString`：
`ZoomViewState(isShown, dockEdge, sourceRectDocPx, magnification,
advanceRegionWidthDp, panelInTopHalf)`——此前漏登记第 6 字段。

**写链**（`egg.java` case 0，`fgg.java:114` → `zt8` 流收集）：
`z04(z, l6a, l6a)` 组合两个布局位置状态流 → Boolean → `egg` 写
`panelInTopHalf`。即面板实际布局 y 位置是否位于屏幕上半区的派生态。

**读链**（`ahg.java:33`）：`ahg.S = ko4.f(ufbVar, svf(19))` =
`isShown && panelInTopHalf` 派生流 → `u49.java:1212` 收集为
`gl8VarO5`，两处消费：

1. `u49:1481`：`mx.b(flag ? 1.0f : -1.0f, spec, "chromeFlip")` —
   具名 ±1 动画值；
2. `u49:1625`：传入 `z5c.c(...)` 参数 `z3` → `b7f.a` 内部
   `jw0(0.0f, flip)` —— **zoom 控制条镀铬（"toolboxFlip"）垂直镜像**：
   面板在屏幕上半区时控制条/箭头方向翻转（writing chrome 跟随
   重力方向重排）。

## 3. Harmony 移植映射

| 原版 | Harmony（Phase 752） |
|---|---|
| `rh8.u(f, 48, 336)` | `ZOOM_ADVANCE_WIDTH_MIN/MAX_VP = 48/336`（drag onActionUpdate 夹取） |
| `panelInTopHalf`（布局流派生） | `!dockBottom`（Harmony 仅允许 Top/Bottom 停靠，上半区≡顶部停靠） |
| `toolboxFlip` scaleY ±1 动画 | 控制条 Row `.scale({x:1, y: dockBottom?1:-1})`（无过渡动画——即时翻转近似） |

## 4. 近似登记

- `panelInTopHalf` 原版是连续布局派生态（面板可悬浮中间态）；Harmony
  停靠为离散 Top/Bottom —— `!dockBottom` 等价覆盖两个可达态。
- 翻转即时生效，无 300ms spring 过渡（`s01.Y(...)` spec 细节不可见）。
- 翻转范围按 `xwa` 组合体的控制条镀铬近似——书写画布不镜像
  （镜像笔迹会造成书写方向错乱，判断原版的画布内容变换独立于
  chrome 翻转）。
- `svf(20/21)`（`ra3.m` 手势面流）经 `ahg.T/U` 派生，已在
  `toolChangedAt`/手势面门控中覆盖。

## 5. 文件清单

- `note/src/main/ets/ui/editor/NoteZoomView.ets`：`ZOOM_ADVANCE_WIDTH_*`
  常量 + drag 夹取域更正 + 控制条 `.scale({y:...})` chromeFlip。
