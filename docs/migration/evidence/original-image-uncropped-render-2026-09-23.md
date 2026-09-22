# 原版证据：裁剪会话期间图片按未裁剪全图渲染（itc.c / showUncropped）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 604 依据。

## 1. 选区态字段（itc.java:57）

```java
public final String toString() {
    // "Tap(selectedId=…, id=…, showUncroppedImage=…)"
    return od4.m(sb, this.c, ")");
}
```

`itc`（Tap 单元素选区）第三布尔字段 `c = showUncroppedImage`。
`dhb` case14（CROP 菜单动作）经 `fvb.e(true)` 置位；裁剪收尾路径
（`ns` coroutine 恢复分支）复位 `e(false)`。即：进入裁剪会话 →
选中的图片块以"未裁剪"方式呈现。

## 2. 渲染管线消费（l0f.java:103 / m2f.java:109）

```java
// TileSubmission.toString 字段序（l0f.java:103）：
//   …, staticSelectionState=this.p, liftState=this.q,
//   showUncropped=this.r, pdfTextSelectionState=this.s, …
// TiledRendererUpdate.toString 字段序（m2f.java:109）：
//   …, staticSelectionState=this.i, showUncropped=this.j, …
```

瓦片提交/更新都把 `showUncropped` 传给渲染器：裁剪会话期间该图片块
渲染整张原图（忽略 cropRect 的像素裁剪与块矩形 clip），草稿矩形
因此可以拖进"已裁掉的域"。

## 3. 语义对齐点

- `hp5.cropRect` 与 `dp5.size`（块宽高）共享"已定向图片域"单位
  （`OriginalImageCropGeometry` 注释同一结论，`beginOriginalImageCrop`
  强制 `numbersNear(cropW, blockWidth)`）。
- 未裁剪渲染 = 在本地块坐标系内，将全图平移 `(-source.left,
  -source.top)`、按 `intrinsic/oriented` 缩放到 intrinsic 单位，
  使 `session.domain = [-source.left, -source.top,
  intrinsic-source.left, intrinsic-source.top]` 恰好是整张图的可见域。
- EXIF 方向与 `imageFlipped*` 用户翻转仍在像素空间内先应用，
  与正常裁剪渲染的顺序一致。

## 4. Harmony 缺口与修复

缺口：`imageCropVisible` 期间图片仍按 `cropRect` 裁剪渲染并 clip 到
`blockWidth×blockHeight`，draft 矩形拖到当前裁剪域之外时手柄悬空
在空白上（看不到可裁入的像素）。

修复：`ImageCanvasRenderer.renderImage` 增加可选 `uncroppedSourceCrop`
参数；`NoteCanvasView` 渲染循环中当 `imageCropVisible` 且元素 id ==
`imageCropSession.original.id` 时传 `session.sourceCrop`，其余图片
与未在裁剪时保持原路径。
