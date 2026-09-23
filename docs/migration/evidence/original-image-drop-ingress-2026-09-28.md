# 证据：原版画布拖放入口（dr / e0f / pl3）

- 日期：2026-09-28；Phase 630
- 原版来源：`decompiled_1.0.3/sources/defpackage/dr.java`、
  `e0f.java`、`ol3.java`、`ame.java`、`kl3.java`
- Harmony 实现：`note/src/main/ets/ui/editor/NoteCanvasView.ets`、
  `note/src/main/ets/data/OriginalDragDropIngress.ets`、
  `note/src/main/ets/data/OriginalClipboardImageIngress.ets`

## 原版语义

画布拖放是 pl3 消费方链（`dr.onDrag` 按 ACTION 分派，DROP(3) →
`ol3.P0(kl3)` → 末端 `pl3`）。画布图像落点的消费方是 `e0f`：

1. `e0f.P0(kl3)`（e0f.java）：
   - `requestDragAndDropPermissions` 失败 → `return false`；
   - `getClipData()` 为空/无 item → release + `false`；
   - 遍历全部 item，收集 `getUri()` 非空的 URI 进 `ArrayList`；
   - 列表空 → release + `false`；
   - 否则 `wx4.invoke(arrayList, mp5(packXY(getX(), getY()),
     permissions))` —— 把 **URI 列表 + 落点坐标** 交给插入回调，
     `return true`（接受）。
   - 即：原版画布 drop **只认 URI 条目**，文本 item（`getText`）
     在此消费方不消费；不以扩展名预检——解码失败由下游兜底。

2. 另存在文本字段级消费方 `ame.P0`（ame.java）：收集
   `getText()` 非空 item 拼接 `\n` 插入文本字段 `vleVar.Y`——
   属编辑器内文本域拖放，非画布图像落点，本 Phase 不在范围。

3. `dr.onDrag`（dr.java:13）：`case 3: return ol3Var.P0(kl3Var)`
   ——DROP 的接受与否由消费方 `P0` 返回值决定；ENTER/LOCATION/
   EXIT 另有分发（`w0`/`x`/`k0`/`F`），无消费语义。

## Harmony 对齐

- `NoteCanvasView` 根 `Stack` 挂 `.onDrop` → `onOriginalImageDrop`：
  `canStartOriginalPhotoInsert` 门禁（loaded/page/非 busy 同约）、
  `event.getData()` → `extractOriginalDroppedImagePayload`、
  空负载 → `setResult(DROP_DISABLED)`；否则以
  `getWindowX/Y − canvasDropWindowOrigin`（Area.globalPosition，
  onAreaChange 捕获）换组件坐标 → `screenToCanvas` →
  `getOriginalPhotoInsertOrigin(anchor)` → `DROP_ENABLED` +
  `startOriginalDroppedImageInsert`。
- `OriginalDragDropIngress`（新增）：
  - `extractOriginalDroppedImagePayload`：UDMF 记录类型白名单
    `general.file-uri` / `general.image`（string 或 `{uri}`）/
    `general.pixelmap`（duck-type `getImageInfo`）→
    `{uris, pixelMaps}`；其余记录类型/取值异常一律跳过。
  - `importOriginalDroppedImages`：带支持扩展名 URI 走与 picker
    同一条 `importOriginalPhotos` 管线；无扩展名 URI 逐条
    `importExtensionlessDroppedImage`（fileIo 读取 + 104857600 上限 +
    `normalizeOriginalImageBytes` 解码兜底，失败跳过而非中止）；
    pixelmap 记录经 `normalizeOriginalPixelMap`（webp lossy +
    降采样护栏）转 `OriginalPhotoIngressItem`。
  - 全部汇入 `insertOriginalPhotos(imported, origin)`——与
    剪贴板贴图/相册选图共用同一条落点插入与历史管线。
- `OriginalClipboardImageIngress`：归一化主体抽取为导出函数
  `normalizeOriginalPixelMap(pixelMap)`，粘贴与拖放共用。

## 差异与边界

- 原版用 `DragAndDropPermissions` 申请 URI 读权；Harmony 侧拖放
  会话自带临时读权，无需等价物（fail-closed：openSync 失败逐条跳过）。
- `general.image` 记录取值为对象时只认 `.uri` 字符串成员；
  其余形态（HTML 片段、plain text）不入图像负载——与原版
  `getUri()==null` 跳过同约。
- 无扩展名 URI（datashare/media 短链）走解码兜底而非扩展名门禁，
  对应原版"收集全部 URI"语义；picker 入口的扩展名约束保持不变。
- 文本域拖放（ame 消费方）不在本 Phase；Harmony 文本输入框的
  系统级拖放文本插入由 ArkUI 文本组件自带行为覆盖。

## 回放

`docs/migration/replays/d05-original-image-drop-ingress.mjs`：
45 断言全绿（原版证据 11 + Harmony 实现 26 + 抽取/分拣仿真 8）。
