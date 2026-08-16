# 原版 Viewport 缩放范围、锚点与持久化证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/t0g.java`：
  `C25A209750D701F597AB1DB717B6AC7B9C3974C7A0B0B7649582EB50CF648EE7`
- `sources/defpackage/h3a.java`：
  `16EAA44591784E1144CE77D6AF982B1EBE5576896FC0CC933703AC0B4F7ACDAB`
- `sources/defpackage/v0g.java`：
  `A58895AB0CDAC64A1EB62C3B25DCA72D99DC6A3D03121FC9F7065505670FE3EC`
- `sources/defpackage/x0f.java`：
  `013E971EBCDC7144DEDE1186A5F997AC38615E9B734E5C8B122920047EF076D0`
- `sources/defpackage/d2.java`：
  `9A502C856F4714426F42CAC2E1EB7F7D1B3A0FFDDDAD6F8C31D846DADC02A0FA`

## 1. 原版交互范围是 0.25×～10×

`t0g.java:34-36` 在 `ViewportState` 静态初始化中建立 `new ms1(0.25f, 10.0f)`。`h3a.java:35-37`
再次把每次交互缩放写成：

```java
float newZoom = clamp(oldZoom * factor, 0.25f, 10.0f);
float actualFactor = newZoom / oldZoom;
```

因此 Harmony 旧有的 4× 上限不是原版 1.0.3 契约。10× 是交互 viewport 上限；Tape 的 8× pattern
bucket、Math 的 4× source raster bucket 和 PDF 的单张像素预算是各 consumer 的独立质量/资源上限，不能反向
把 viewport 截到 4×。

## 2. 原版缩放使用实际倍率并保持传入锚点

`h3a.java:36-42` 先根据 clamp 后的 `newZoom` 计算 `actualFactor`，再把调用方传入的 packed point
`this.L` 纳入 scroll/translation 更新。到达 0.25× 或 10× 时使用实际可达到的倍率，而不是仍按请求倍率移动
viewport；这正是“屏幕锚点下的页面点不动”的必要条件。

Harmony 的等价形式是：

```text
actual = clampedZoom / oldZoom
newScroll = anchor - (anchor - oldScroll) * actual
```

## 3. 原版恢复时分别验证 zoom 与 scroll

`v0g.java:75-89` 对持久化 zoom 先排除 NaN/Infinity，再要求 `[0.25,10]`；失败只记录
`Discarding corrupt persisted viewport zoom`，不会应用坏值。`v0g.java:90-101` 随后独立读取 packed scroll，
只有 X/Y 都有限时才恢复，否则记录 `Discarding corrupt persisted viewport scroll offset`。

这意味着部分有效状态可以恢复：坏 zoom 不应阻止合法 scroll，坏 scroll 也不应撤销合法 zoom。Harmony
继续在 UI 恢复处分别调用 `setZoomRaw()` 与 `setScroll()`，不把两字段错误地绑定成全有或全无。

## 4. 原版拒绝持久化非有限 viewport

`x0f.java:337-447` 在写入前逐层检查当前 zoom、pixel zoom、translation X/Y 与换算后的 doc offset。
任何非有限值都会记录 `Refusing to persist non-finite viewport state/doc offset`，不会把损坏状态写回数据库。

Harmony 没有原版的 pixel-zoom/doc-offset 双层模型，但其可持久化字段 `zoom/scrollOffsetX/scrollOffsetY`
必须满足相同前提；同时 zoom 还应满足原版交互范围。

## 5. T-034 的 `+/-` 0.25 步进不是原版键盘倍率

Harmony `T-034-canvas-zoom-pan.md` 明确规定右下角控制条按钮“步进 0.25”。旧实现却把这个 delta 作为
`1 + delta` 倍率传给 `zoomAt()`，所以产生 `100%→125%→156%→195%`，与自身按钮契约不符。

原版 `d2.java:193/383` 的键盘 zoom 命令分别调用 `bo6.k(1.2f)` 与 `bo6.k(0.8333333f)`，属于约 20% 的
互逆倍率，不是固定 25 个百分点。本阶段因此只把以下两类证据组合，而不伪称完全相同：

- 原版证据决定 0.25×～10×范围、实际倍率和屏幕锚点算法；
- Harmony 既有 T-034 产品契约决定 `+/-` 使用 `zoom ± 0.25`，再复用同一个锚点算法。

## 移植结论

- 所有 viewport 范围判断复用同一组 0.25/10 常量；不得在 UI、repository 和 renderer 各自写不同上限。
- pinch 继续传倍率；T-034 工具栏按钮使用加法步进，两者不能共用含糊的 `delta` 语义。
- 恢复时 zoom/scroll 独立容错；保存时任何非法字段都拒绝整次写入。
- 10×只证明 viewport 数学和数据边界。完成层、PDF、Tape、Math 在高倍下的像素质量和内存仍需各自设备验收。
