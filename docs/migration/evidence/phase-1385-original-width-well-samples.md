# Phase 1385 — 原版宽度预设槽位笔画样张证据

## 原版槽位结构（decompiled_1.0.3）

`res/layout/setting_pen_width_mini_layout.xml`：
```xml
<ImageView android:id="@+id/width_view"
    android:background="@drawable/setting_mini_attr_bg"
    android:layout_width="24dp" android:layout_height="24dp" .../>
```

- 槽位是 `ImageView`，由 `SpenSettingQTAttributesLayout`/`SpenPenWidthMiniLayout`
  （`com.samsung.android.sdk.pen.setting.*`）注入样张图像 —— S-Pen SDK 专有渲染。
- 语义：槽位显示**该宽度的一笔横向样张**（厚度随预设宽度变化），不显示数字。
- 数字宽度由 `yed.java` 的 `ui_tools__width` = "Width: %1$d" 读数承载
  （Harmony 已在滑杆上方保留该读数）。

## Harmony 落点

`WidthSlider.ets`：预设槽位由 `Text(width)` 改为：

```ts
Row() {
  Row()                       // 横向圆角笔画条
    .width(20)
    .height(wellSampleHeight(width))      // = clamp(width, 2, 16) 像素
    .borderRadius(wellSampleHeight(width) / 2)
    .backgroundColor(colorToHex(brushColor))
}
  .width(36).height(28).borderRadius(8)
  .border({ accent/border by brushWidth===width })   // 选中态不变
  .accessibilityText(width.toString())               // 数值保留为无障碍
  .onClick(setBrushWidth(width, index))              // 行为不变
```

`wellSampleHeight(width) = Math.max(2, Math.min(16, width))`：把 0.5–64pt 的预设宽度
线性缩放进 2–16px 的可见条厚范围，保持厚薄可辨。

## 验证

- Replay `d02-original-width-well-samples.mjs`：13/13。
- `note@default` assembleHap：成功。
- 全量基线：1238/1238。
