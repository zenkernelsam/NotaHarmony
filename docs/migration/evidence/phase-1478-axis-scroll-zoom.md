# Phase 1478 — 指针轴事件：Ctrl+滚轮视口中心缩放 / 无修饰滚动平移 / 触控板捏合

## 原版证据（decompiled_1.4.2）

### Ctrl 状态发布链

- `uc8.java`：`UiState(isCtrlKeyDown=...)` 字符串形式坐实
  `uc8.a` = Ctrl 键按下态。
- `bd8.java`：`b0 = ptg` 状态槽，键盘事件路径把 Ctrl 按下态
  发布给指针层。
- `ip8.java`：组合 `(uc8.isCtrlKeyDown, mfc)` → 启动 `hp8` 协程。
- `hp8.java`/`gp8.java`：收集 `i8d.G` 指针事件流，过滤
  `PointerEventType == 6`（Scroll），提取打包 scrollDelta
  （long：高 32 = horizontal、低 32 = vertical），启动
  `dx(ctrl, mfc, delta)`。

### `dx.java` byte-2（单类 JADX 反编译取得完整 invokeSuspend）

```java
// ctrl == true：
float dy = Float.intBitsToFloat((int) (delta & 0xFFFFFFFFL));
float f = 1.0f - dy * 0.2f;
long center = pack(mfc.p().width / 2, mfc.p().height / 2);
mfc.D(f, center, qs2);              // 视口中心缩放
// ctrl == false：
int hx = (int) (Float.intBitsToFloat((int) (delta >> 32)) * -50.0f);
int vy = (int) (Float.intBitsToFloat((int) (delta & 0xFFFFFFFFL)) * -50.0f);
mfc.a(pack(hx, vy), qs2);           // 视口平移
```

### `mfc.a` → `dfc` → `mfc.A` 平移语义

- `dfc.java` byte-0：`mfc.A(scope, xxb.f(mfc.l(), Δ))`——
  `xxb.f` = Offset 减法 → 滚动目标 = `l() − Δ`。
- `Δ = −50·axis` → `pos' = pos + 50·axis`。
- 符号佐证：`mfc.i()` 返回 `+0.9·视口高` 供 `f2` PAGE_DOWN 支
  → `mfc.s→ad8→mfc.x(l()+0.9h)` = 向下滚动——`pos+` = 视图向下。
- 净效果：滚轮向下（axis+）→ 视图向下滚 50px/单位 Δ；
  水平轴同理。

### `mfc.D(f, pivot)`

缩放至 `zoom·f`，锚点 `(p()/2)` = **视口中心**（非光标位置）。
`dy>0`（滚轮向下）→ `f<1` → 缩小；`dy<0` → 放大。

## Harmony 通道核实（SDK `common.d.ts`）

- `onAxisEvent(Callback<AxisEvent>)`（API17）；
- `AxisEvent.action: AxisAction`（BEGIN/UPDATE/END/CANCEL）；
- `getVerticalAxisValue()`/`getHorizontalAxisValue()`（vp，
  官方文档：**正值 = 滚轮向后/向下滚动**——与 Compose
  `scrollDelta` 同向）；
- `getPinchAxisScaleValue()`（API21）= 触控板双指捏合缩放轴；
- `BaseEvent.getModifierKeyState?(keys)`（API12，
  `'Ctrl'|'Alt'|'Shift'`）→ 替代原版 uc8 状态流。

## Harmony 落点

`NoteCanvasView` Canvas `.onAxisEvent` → `onCanvasAxisEvent`：

| 原版 | Harmony |
|------|---------|
| `PointerEventType==6` 过滤 | `BEGIN/UPDATE` 动作过滤；END/CANCEL → `schedulePdfRasterRefresh(0)`（对齐手势尾） |
| Ctrl+轮 → `mfc.D(1−Δy·0.2, 视口中心)` | `zoomAt(width/2, height/2, 1−Δy·0.2)` |
| 无修饰 → `pos += 50·Δ` | `panBy(−50·Δ)`（`scrollY` = 内容偏移 ≡ −pos） |
| 触控板捏合（scale 手势通道） | `getPinchAxisScaleValue()>0&&≠1` → `zoomAt(event.x, event.y, scale)`（光标锚点 = 原版捏合焦点等价） |

门集与 `onCanvasTouch` 对齐：`!loaded/dataLoading/
dataLoadFailed/photoImportBusy/historyBusy/pinchSelectSession`。

## 登记的差异

- 轴值幅值：Compose `scrollDelta` 每格 ≈±1；Harmony 轴值单位 vp、
  受系统滚轮步长（`scrollStep`）影响。公式按原版逐字移植
  （`1−Δ·0.2`、`−50·Δ`），幅值差异属平台报告约定，
  `zoomAt` 内部 `clampZoom[0.25,10]` 与 `factor>0` 检查兜底。
- 触控板捏合轴为 API21+ 能力；原版经 scale 手势到达同一缩放
  语义，通道不同、行为等价。

## 验证

- fixture `d02-original-axis-scroll-zoom.mjs`：21 checks
  （常量/挂载/门集/三分支/可执行 pos↔scrollY 符号模型）。
- `note@default` assembleHap：BUILD SUCCESSFUL。
- 全量基线、双 HAP：见 Phase 1478 report。
