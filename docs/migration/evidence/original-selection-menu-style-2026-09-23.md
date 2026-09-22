# 原版证据：选区菜单 STYLE = 样式选择表面（dsc.STYLE / ux9）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 595 依据。

## 1. `dsc.STYLE` = 菜单首项（`dsc.java`）

```java
public static final dsc a = new dsc("STYLE", 0);      // ordinal 0 = 菜单首项
public static final dsc b = new dsc("COPY", 1);
public static final dsc c = new dsc("CUT", 2);
...
public static final dsc u = new dsc("DESELECT", 20);
public static final dsc v = new dsc("MORE", 21);
```

`dsc` 枚举声明顺序即选区菜单顺序——`STYLE` 是原版选区菜单的
**第一项**，排在 `COPY` 之前。

## 2. STYLE 菜单项构造（`ux9.java`）

`ux9` 把每个 `dsc` 序数映射成菜单项（`r68`）：

- STYLE 项使用 `R.string.feature_note__selection_menu_style`
  （标签 "Style"）与 `feature_note__selection_menu_style_outline`
  （图标轮廓资源）。
- 点击 STYLE → 以选中 ink 当前颜色为 HSV 种子构造样式选项状态
  （`nsc`/`ru1` 族：色板 + 宽度候选），弹出样式选择表面。
- 表面里点选颜色/宽度 → 对选中元素应用样式并记录可撤销修改。

## 3. 应用路径（`dhb.java` + ink registers）

`dhb` 的 STYLE 分发把样式写入选中 ink 的寄存器：
颜色 HSV → int color；宽度值 → brushWidth/geometry 重建——
与工具栏颜色井/宽度井共享同一修改通道（原版工具栏与选区菜单
STYLE 写同一组 ink register）。

## 4. 可见性

STYLE 仅在选区含可样式化元素（ink：笔画/形状）时出现；
纯文本/图片/数学选区不出 STYLE 项。

## 5. Harmony 侧对应

Harmony 已具备全部应用通道（此前 Phase 落地）：

- `EditorToolbar` 弹层：`ColorPickerView`（`selectionMode` +
  `selectionColor` + `onSelectionColor`）与 `WidthSlider`
  （`selectionMode` + `selectionWidth` + `onSelectionWidth`）。
- `NoteCanvasView.modifySelectedInkRegisters`：对选中笔画/形状
  应用颜色+宽度，含撤销快照、荧光笔 alpha、胶带宽度界、
  铅笔宽度重建——即原版 ink-register 写的等价物。
- `NotePage` 持有 `selectionInkColor`/`selectionInkWidth`/
  `selectionColorSignal`/`selectionWidthSignal` 并经信号属性
  驱动画布。

缺口仅在选区菜单：菜单从 `COPY` 起排，无 `STYLE` 项。
