# Phase 749 证据：原版 Zoom 自动前进区宽持久化（o59.r / n27）

> 证据基准：`decompiled_1.0.3/sources/`（JADX 反编译 1.0.3）。
> Zoom View 结构/控制条证据见 `phase-747-original-zoom-view.md`，
> 放大面渲染范围见 `phase-748-original-zoom-view-full-render.md`。

## 1. 偏好键与默认值

`defpackage/o59.java:23`：

```java
public static final eua r = new eua("zoomViewAdvanceRegionWidthDp");
```

`eua` 为 Preferences DataStore 键对象（同文件 `h..s` 一组编辑器设置键，
`l59.java:65` 的设置 dump 里该键与 `hideNavigationBar` 等并列打印）。
`ggg.e advanceRegionWidthDp` 默认 `180.0f`（lgg 初始状态）。

## 2. 写路径（拖拽 → DataStore）

`defpackage/g0j.java:250`：

```java
htd htdVar = new htd(1, ahgVar, ahg.class, "setAdvanceRegionWidth",
    "setAdvanceRegionWidth(F)V", 0, 18);
```

advance_tab 拖拽回调以 `hk6`/`ix4`（suspend function）形式绑定
`ahg.setAdvanceRegionWidth(F)`；`defpackage/n27.java:42`：

```java
case 2:
    tk8 tk8Var = (tk8) obj;
    tk8Var.getClass();
    tk8Var.g(o59.r, Float.valueOf(f));
    break;
```

`tk8` 为 DataStore 编辑器——每次 `setAdvanceRegionWidth` 调用都把 Float
写入 `zoomViewAdvanceRegionWidthDp`。**即用户调整的前进区宽跨会话保留**；
下次进编辑器打开 Zoom View 时读出上次的值，而非回退 180dp。

## 3. 读路径

`defpackage/bc7.java:211`（case 27 批量收集）：`tk8Var2.f(o59.r)` ——
随其余编辑器设置一并从 DataStore 读入。

## 4. Harmony 原状缺口

Phase 747 的 `zoomAdvanceWidthVp` 是 `NoteCanvasView` 内 `@State`，每次
编辑器挂载重置为 180——跨会话记忆缺失，与 `o59.r` 持久化语义不符。

## 5. Harmony 修复落点（Phase 749）

- `EditorSettingsStore`：新增 `zoomViewAdvanceRegionWidthDp`（键名照抄原版）
  + `DEFAULT_ZOOM_ADVANCE_WIDTH_DP=180` + number 型 get/save（沿用 mutex +
  flush 失败回滚的既有范式）；
- `EditorViewModel`：`zoomAdvanceWidthDp` 字段随编辑器设置块加载，
  `setZoomAdvanceWidthDp` 走 `enqueueSave` 乐观写 + 失败回滚；
- `NoteCanvasView`：`initZoomSourceRect` 挂载时同步 VM 持久化值；
  `onAdvanceRegionCommit` 拖拽提交点调 VM setter，失败回滚本地 @State；
- `NoteZoomView`：advance_tab `PanGesture` 增加 `onActionStart`（钉住拖拽
  起点宽，修复 offsetX 累计值被逐帧重复相减的漂移）与 `onActionEnd`
  （提交持久化点）。

### 登记近似

原版 `setAdvanceRegionWidth` 每次拖拽回调都写 DataStore；Harmony 在
`onActionEnd` 提交点写一次——跨会话可观察语义等价，拖动过程不落盘写。
