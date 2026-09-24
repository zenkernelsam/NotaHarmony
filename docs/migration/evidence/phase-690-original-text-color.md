# Phase 690 — 原版文字颜色（qte → zyd.g foregroundColor）Evidence

## 范围

把原版文字色井/色板（`qse.O` 面板 → `qte`/`ste` 事件 → `zyd.g` iu1
负载）移植到 Harmony 文本块编辑覆盖层：`foregroundColor` 字符样式 run
的写入、选区应用、折叠光标预期属性和 "Automatic" 恢复缺省色。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— `qte` 分支（L370-377）

```java
if (nueVar instanceof qte) {
    long j = ((qte) nueVar).a;                 // 选中的 iu1 颜色（long）
    do {
        asdVar2 = this.Y;                       // 文字色井态
        value2 = asdVar2.getValue();
        ((iu1) value2).getClass();
    } while (!asdVar2.i(value2, new iu1(j)));   // 更新色井当前色
    n(new zyd(null, null, null, null, null, null,
        new iu1(j),                             // arg7 = foregroundColor
        null, null, null, null, 1983));
    return;
}
```

`qte.toString = "OnForegroundColorSelected(color=...)"`。

### 2. `cve.java` —— `ste` 分支（L379-386）

```java
if (nueVar instanceof ste) {
    j().e.f(((ste) nueVar).a);   // fm7.e.f(color)：直接写选区文字色
    i(qse.S);                    // 收色板面板
    return;
}
```

### 3. `cve.java` —— `hue` 分支（L265-269）

`nueVar.equals(hue.a)` → `asd.k(null, qse.O)` 打开文字色面板
（`i31` 字体面板内的色井区）。

### 4. `sources/defpackage/zyd.java`

`public final iu1 g` —— `zyd` 字符样式负载第 7 字段为前景色
（与 P684-688 解码的 bold/italic/underline/eh5/familyName/fontSize/
link/sub/sup/strike 同一分派表）。

### 5. 语义

- `zyd.g` 显式设置 → span 前景色；
- 字段缺省 → `element.fontColor`（元素级缺省字色）；
- 原版无 "remove foreground" 动作——缺省即回退元素色。

## Harmony 现状（Phase 690 之前）

- `RichTextCharacterStyle.foregroundColor?: number` 字段存在；
  `Canvas2DTextRenderer` renderSpan 已用
  `style.foregroundColor ?? element.fontColor` 填充文字。
- Phase 684/688/689 字符 run 管线 + pending 落地机制齐备。
- 缺口：**无 authoring 入口**。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `hue`→`qse.O` 色板面板 | `Color` 按钮 + `bindSheet` 调色网格（`SheetSize.MEDIUM`） |
| `qte`/`ste` 写 `zyd.g` | `pickTextColor(color)` → `applyForegroundColor(color,s,e)` 写 `foregroundColor` run |
| 色井当前色态 `this.Y` | 无全局色井——sheet 即开即选（受限等价，见下） |
| 缺省字色（字段缺席） | `Automatic` 项 → `applyForegroundColor(null)` 置 `foregroundColor=undefined`，JSON 规范归并剔空样式 |
| 折叠光标预期 | `pendingCharStyles.foregroundColor` + `pendingClearForeground` |
| 12 色预设 | `TEXT_COLOR_PRESETS`（与 `ColorPickerView.presetColors` 同源 12 色 ARGB） |

## 受限等价说明（非 ADR 级）

原版的文字色是"色井驱动"：色井持有当前色（`this.Y`/`br2`），格式行色井
按钮用当前色直接应用、长按开面板。Harmony 侧复用 `bindSheet` 调色网格
（与工具栏 `ColorPickerView` 同源预设）：点开即选色——点选=应用该色
（等价 `qte`→`zyd.g`），Automatic=字段缺省。差异仅为色井"当前色一键
应用"手势——sheet 已一步选色，无语义损失。沿用 ADR-0650 字符样式分派
框架，不立新 ADR。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-text-color.mjs`：16 项静态钉全绿。
