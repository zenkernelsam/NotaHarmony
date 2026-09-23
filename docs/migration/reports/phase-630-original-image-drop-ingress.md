# Phase 630 — 画布图像拖放入口（e0f.P0 URI 落点插入对齐）

## 原版证据

- `dr.java:13-56`：`onDrag` 按 ACTION 分派，`case 3`（DROP）→
  `ol3Var.P0(kl3Var)` —— 由 pl3 消费方决定接受与否；
- `e0f.java`（`implements pl3`，`P0`）：画布 drop 消费方 —
  `requestDragAndDropPermissions` 失败 / `getClipData()` 空 /
  URI 收集后仍空 → release + `return false`；否则
  `wx4.invoke(arrayList, mp5(packXY(getX,getY), perms))`
  —— URI 列表 + 落点坐标交插入回调，`return true`；
- `ame.java`：文本字段级消费方（`getText()` 拼接插入文本域），
  非画布图像落点——不在本 Phase。

净效果：**原版画布拖放只消费 URI 条目，按落点插入**；不带
URI 的 item 被跳过，全空则不接受。

## Harmony 实现

- `note/src/main/ets/data/OriginalDragDropIngress.ets`（新增）：
  - `extractOriginalDroppedImagePayload(UnifiedData)` —— UDMF
    白名单 `general.file-uri`/`general.image`/`general.pixelmap`
    → `{uris, pixelMaps}`，其余类型/取值异常跳过；
  - `importOriginalDroppedImages` —— 带扩展名 URI 走
    `importOriginalPhotos`（picker 同管线）；无扩展名 URI 经
    `importExtensionlessDroppedImage` 解码兜底逐条跳过；
    pixelmap 经 `normalizeOriginalPixelMap` →
    `OriginalPhotoIngressItem`；
- `note/src/main/ets/data/OriginalClipboardImageIngress.ets`：
  归一化主体抽取导出 `normalizeOriginalPixelMap`，
  `importOriginalClipboardImage` 行为不变；
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：
  - 根 `Stack` 挂 `.onDrop` → `onOriginalImageDrop`；
  - `onAreaChange` 捕获 `globalPosition` 存
    `canvasDropWindowOrigin`；
  - 落点 `getWindowX/Y − 原点` → `screenToCanvas` →
    `getOriginalPhotoInsertOrigin(anchor)`；
  - `canStartOriginalPhotoInsert` 门禁 + `DROP_ENABLED`/
    `DROP_DISABLED` 回执 + `startOriginalDroppedImageInsert`
    （`photoImportBusy`、generation/page 校验、
    `insertOriginalPhotos`、`onPhotoIngressFinished` 收尾）。

## 验证

- 专项 Replay：`d05-original-image-drop-ingress.mjs`
  **45/45 全绿**；
- 全量 Desktop Replay：见下方（本 Phase 报告时执行）；
- `note@ohosTest` / `note@default` clean 构建成功；
- ArkTS 静态检查：无新增错误（仅既有 deprecation 告警）。

## 边界与已知差异

- 拖放会话读权由 Harmony 系统授予，无
  `requestDragAndDropPermissions` 等价物；
- 无扩展名 URI 走解码兜底而非扩展名门禁（原版"收集全部 URI"
  语义）；
- 文本域拖放（ame）不在范围；
- 真机拖放手感、多类型记录（HTML/base64 image）覆盖列
  真机复验清单。

## 交接衔接

修复总纲"Pasteboard/相机/拖放"开放项中的**拖放入口**至此落地；
剩余 Pasteboard 富格式与相机真机项仍开放。T-042 继续保留为
Goal 最后一项。
