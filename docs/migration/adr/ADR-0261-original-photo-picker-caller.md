# ADR-0261：Harmony PhotoViewPicker 生产 Caller

- 状态：Accepted（Phase 283，2026-08-23）
- 范围：工具栏 Photo → 有序 URI 选择 → Phase 282 ingress → 多图 durable insert → Undo / 画布状态
- 相关：ADR-0258、ADR-0259、ADR-0260

## 决策

新增 `OriginalPhotoPickerCaller.ets`，默认使用本地 SDK 的
`@kit.MediaLibraryKit > photoAccessHelper.PhotoViewPicker`：

```text
PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber = 500
  -> photoUris in result order
  -> validateOriginalPhotoSelection()
  -> importOriginalPhotos(uris, cacheDirectory)
```

选择器可注入用于静态 fixture；生产路径不启动模拟器或 Hypium。Phase 282 的 all-or-nothing 校验、100 MiB
闸门、规范化与临时文件清理保持不变。

## 编辑器接线

1. `EditorToolbar` 在展开区和 compact 菜单新增 Photo；
2. `NotePage` 通过递增 `photoInsertSignal` 转发到画布；
3. `NoteCanvasView` 用独立 `photoImportBusy` 防止 picker/import 与持久化重入；
4. ingress 返回项按输入顺序映射为 `OriginalImageInsertPersistencePlan`；
5. anchor 以页面中心为基准，多图按索引偏移 24 个页面单位；
6. 每张图复用既有 `commitOriginalImageInsert()` 的原子资产/事务/history 路径；
7. 成功后使用最后一次返回的 element order 更新画布，并把本次全部图片加入一个 `ADD_ELEMENTS`
   undo action。

## 失败语义

空列表、未支持格式、超限、读取失败或任何一张图持久化失败都会 fail closed。已成功的前序图片不会被回滚成
“整批不存在”，因为每张图本身是原版对齐的 durable operation；但本批不会推进 UI undo action，用户会收到
失败 toast 并可通过既有 Undo 撤回已提交图片。后续如需严格跨图事务，必须扩展 persistence 层而不是在 UI 层伪装。

## 明确未闭环

- 真实设备 provider URI 权限、HEIC/HEIF/TIFF/GIF decode 与 WebP encoder 支持矩阵未验收；
- 相机、Pasteboard、拖放和其他入口未接线；
- 多图跨张事务性 rollback 未实现；
- 大批量内存、性能、错误恢复和端到端体验待设备验证；
- `T-042` 继续保留为整个 Goal 最后一项。
