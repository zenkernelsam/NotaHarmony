# Evidence: `ui_tools__` 族尾部（JADX）

- 日期：2026-09-25
- Phase：720（ADR-0668）
- 证据来源：`decompiled_1.0.3`（只读）

## width — 字号读数 "Width: %1$d"

`yed.java:153/259/379/488` 四处 `tl7.T(ui_tools__width, y0(f)+1)`——
宽度滑块 sheet 的读数标签。Harmony `WidthSlider` 原为 `'Width: ' +
N` 字面量 → 资源化 `ui_tools_width`（`Math.round` 对齐整型）。

## 选区模式（jfh）

```java
// jfh.java:39-53
uni.a(iconA, "Box" /*select_box_label*/, "Rectangle selection" /*rect_mode*/, enabled, …);
uni.a(iconB, "Free" /*freehand_label*/, "Freehand selection" /*freehand_mode*/, enabled, …);
```

原版为 Box/Free 两枚单选图标各挂 mode 语义；Harmony 为单切换钮
（Freehand/Rectangle 标签）→ 挂当前模式的 mode 语义描述。

## 工具箱默认集（rz1.q / a6f / y5f / x82.r）

```
rz1.q():  u5f 主托盘默认 8 项 = PEN,PENCIL,HIGHLIGHTER,ERASER,TEXT,
          SELECT,MEDIA(O),RECORD(P)
rz1.r():  次托盘 = POINTER(Q),LASER(R),ZOOM(U),REVIEW(S),RULER(T)
y5f:      u5f→r5f 状态工厂 case6→x4f(MEDIA)、case7→e5f(RECORD)
x82.r:    a6f→label：case6=ui_tools__media("Media")、case7=record
```

MEDIA/RECORD 为原版工具箱画布工具（x4f/e5f 是 r5f 工具态）。
Harmony 经工具栏加项菜单与录音面板交付同名能力，无画布工具激活面
→ 边界登记（非 fail-closed：功能可达，交互形态不同）。

## 其余键处置

- `stroke`/`fill`/`no_fill`（hx1 STROKE/FILL 页签、r22）：形状属性
  sheet 未移植（fillColor 数据层随形状检测往返）→ 边界登记。
- `color_options`/`open_color_wheel`/`recent_colors`：o4j chevron、
  r22 轮盘图标、rw1 recents 图标的 a11y——Harmony 取色面板无对应
  节点（eyedropper/add_a_color/recents 点列已移植）。
- `pointer`/`ruler`/`zoom`：ADR-0644（POINTER 协作域）、ruler 原版
  隐藏、ZOOM flag——已登记。
- 通用键 `back`/`cancel`/`confirm`/`delete`/`colors` 已有等价资源。

## Replay

`d02-original-ui-tools-tail.mjs`（12 pins）。
