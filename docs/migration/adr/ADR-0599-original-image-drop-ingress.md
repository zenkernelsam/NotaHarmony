# ADR-0599: 画布图像拖放入口（e0f.P0 URI 落点插入对齐）

- 状态：accepted（2026-09-28，Phase 630）
- 证据：`docs/migration/evidence/original-image-drop-ingress-2026-09-28.md`

## 背景

原版画布注册 `dr.onDrag` → `ol3` → pl3 消费方链；图像落点
消费方 `e0f.P0` 收集 ClipData 全部 `getUri()` 非空 item，
连同落点 `(x,y)` 调 `wx4.invoke(list, mp5(packedXY, perms))`
插入；空集/权限拒绝 → `false`（不接受拖放）。

Harmony 侧此前完全没有 `onDrop`/`DragEvent` 接线——外部应用
拖入的图像无法入画布，属修复总纲登记的开放项
（"Pasteboard/相机/拖放"中的拖放入口）。

## 决定

1. 编辑器根 `Stack` 挂 `.onDrop` → `onOriginalImageDrop`：
   - 门禁复用 `canStartOriginalPhotoInsert`（lifecycle/loaded/
     非 historyBusy/非 photoImportBusy/持久层就绪/页一致）；
   - `event.getData()` → `extractOriginalDroppedImagePayload`；
     空负载或异常 → `setResult(DROP_DISABLED)`；
   - 落点 = `getWindowX/Y − Area.globalPosition`（组件坐标）→
     `screenToCanvas` → `getOriginalPhotoInsertOrigin(anchor)`；
   - `setResult(DROP_ENABLED)` 后异步
     `startOriginalDroppedImageInsert`——`photoImportBusy` +
     generation/page 失效校验 + `insertOriginalPhotos` 管线 +
     `onPhotoIngressFinished` 收尾，与剪贴板贴图同约。
2. 新增 `OriginalDragDropIngress.ets`：
   - 记录类型白名单：`general.file-uri`/`general.image`/
     `general.pixelmap`；image 对象取 `.uri`，pixelmap 走
     duck-type `getImageInfo` 识别；
   - 带支持扩展名 URI → `importOriginalPhotos`（picker 同管线）；
     无扩展名 URI → `importExtensionlessDroppedImage` 解码兜底
     （fail-closed 逐条跳过，对齐原版不以扩展名预检）；
   - pixelmap → `normalizeOriginalPixelMap`（与剪贴板共用
     webp lossy + 降采样护栏）。
3. `OriginalClipboardImageIngress` 归一化主体抽取为导出
   `normalizeOriginalPixelMap`；`importOriginalClipboardImage`
   行为不变。

## 差异声明

- 原版 `requestDragAndDropPermissions` 显式授权；Harmony 拖放
  会话由系统授予临时读权，无等价 API，读失败逐条跳过。
- 无扩展名 URI 仍尝试解码（原版语义）；picker 入口扩展名约束
  不变——两处调用方策略不同，属有意分叉。
- 文本域拖放（`ame`）与画布内文本插入不在本 Phase；ArkUI 文本
  组件自带的系统拖放文本插入行为未被本实现覆盖或替代。

## 验证

- 专项 Replay `d05-original-image-drop-ingress.mjs` 45/45；
- `note@default`/`note@ohosTest` 静态构建 0 新增错误；
- 真机拖放手感与多类型记录覆盖率列入真机复验清单。
