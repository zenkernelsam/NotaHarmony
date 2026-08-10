# ADR-0032：原版 IMAGE 缩略图 renderer

- 状态：Accepted（静态缩略图边界；动画与远端刷新仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0030、ADR-0031、M2-R-06

## 原版证据

原版 1.0.3 的页面内容渲染由 `b40` 对 `hp5` 统一生成 IMAGE render node；缩略图并没有第二套 crop/flip 几何语义。
`b40.D/E` 的静态图片解码、最大边 3000、crop、block transform、clip 与双 flip 顺序因此同样适用于页面缩略图。
GIF 仍由 `hp5` 的独立 view type 表达，不能在缩略图路径把首帧冒充完整动画支持。

## 决策

`ThumbnailRenderer` 复用 `ImageAssetLoader` 与 `ImageCanvasRenderer`，不复制主画布的图片算法。绘制前按原版 storage hash
去重加载当前页 IMAGE；随后在 `loaded.elements` 的统一顺序中与 Stroke、Text、Shape 交错绘制。只有 `READY` 且 bitmap
非空的静态资产进入 Canvas；MISSING、PENDING、FAILED 与 ANIMATED_UNSUPPORTED 保持纸张上的空缺，不中断整张缩略图。

每次缩略图调用只拥有本次加载的资产。无论正常返回、Canvas 异常还是 PixelMap 创建失败，`finally` 都通过 loader 关闭
ImageBitmap 并释放 PixelMap。返回的缩略图 PixelMap 仍由 LibraryPage 现有 generation/LRU 生命周期持有和释放。

## Deferred 边界

本阶段不实现 GIF 动画缩略图、远端 asset transport 或资产状态变更的主动缓存失效通知。当前导入与本地保存会在页面内容
revision 变化后重建缩略图；未来网络资产由 PENDING 转为 LOCAL 时，transport 必须触发资料库 thumbnail generation 更新。
caption 与 ROUND corner 像素裁剪继续 Deferred。

## 验证

- `d02-image-thumbnail.mjs`：storage hash 去重、统一 IMAGE 分支、READY 门禁、共享 renderer、`finally` 释放和 Library DB 接线。
- 全量 Node/SQLite replay：`TOTAL=41 FAILED=0`。
- `hvigor clean` 后双 HAP 构建结果记录于阶段报告。
- 未启动模拟器/真机，未执行图片缩略图像素对照或滚动内存曲线。
