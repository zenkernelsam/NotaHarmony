# ADR-0260：原版照片 URI Ingress 边界

- 状态：Accepted（Phase 282，2026-08-22）
- 范围：有序照片 URI 列表 → MIME/扩展名门禁 → 有界读取 / cache copy → Phase 281 规范化 → 可插入快照
- 相关：ADR-0258（图片插入原子持久化）、ADR-0259（大图规范化 Adapter）

## 决策

新增 `OriginalPhotoIngress.ets` 作为生产 caller 与规范化器之间的可注入边界：

```text
ordered photo URIs
  -> all-or-nothing extension validation
  -> bounded URI read
  -> temporary cache copy
  -> normalizeOriginalImageBytes()
  -> ordered normalized snapshots
  -> always remove temporary copies
```

返回项包含 `bytes`、稳定生成文件名、最终 MIME、encoded/oriented dimensions。该结果可直接转换为
`normalizedOriginalImagePersistencePlan()` 与 `commitOriginalImageInsert()` 所需的输入，但本阶段不接线
picker 或 toolbar。

## 原版对齐与平台差距

1. Android `oj3.java` 的 png、jpg、jpeg、webp、tif、tiff、gif、heif、heic allowlist 原样保留。
2. `tf9.java` 先校验整个选中列表；任一 URI 不合法即失败，不产生部分插入。
3. `bgj.d(Context, Uri)` 通过 cache temp file 复制 URI，并使用 `fag.z(..., 104857600L)` 限制为
   恰好 `104857600` bytes。
4. Harmony URI reader 显式允许读入 `limit + 1` byte，随后由统一 gate 拒绝空文件和超限文件；
   这样不会把截断的 100 MiB 内容伪装成完整原图。
5. 成功、解码失败或写入失败都会清理本次创建的临时路径。

Android `ContentResolver.openInputStream(Uri)` 在 Harmony 当前代码路径映射为 CoreFileKit 直接打开 photo
URI。系统 picker 返回的 provider URI 兼容性仍需后续真实设备验证；当前实现不伪造 ContentResolver 行为。

## 测试边界

- `validateOriginalPhotoSelection()` 和 `isValidOriginalPhotoUri()` 覆盖 allowlist 与 all-or-nothing。
- `isOversizedOriginalPhoto()` 覆盖非安全整数、空文件、恰好上限与超限一字节。
- URI reader 可注入，静态 fixture 不启动系统应用、模拟器或 Hypium。
- 专项 Replay 同时锁定原版证据位置、Harmony 行为、临时文件清理与“UI/caller 明确延后”。

## 明确未闭环

- PhotoViewPicker/CoreFileKit 生产 caller、权限与用户错误提示未接线；
- toolbar/product UI 未增加；
- Pasteboard、相机、拖放与其他 ingress 未处理；
- HEIC/HEIF/TIFF/GIF decode、EXIF 变体、WebP 支持矩阵与真实设备内存/延迟未验收；
- Undo/Redo、重启、同步导入导出与端到端体验继续开放；
- `T-042` 继续保留为整个 Goal 最后一项。
