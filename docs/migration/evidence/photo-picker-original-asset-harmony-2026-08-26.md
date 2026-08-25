# Harmony 证据 — 照片 Picker 原始资产门禁

- 文件：`note/src/main/ets/data/OriginalPhotoPickerCaller.ets`
- 本地 SDK：
  `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.file.photoAccessHelper.d.ts`
- SDK 事实：`PhotoSelectOptions.maxSelectNumber?: number` 控制“单次选择最大图片数”；
  `PhotoSelectResult.photoUris: Array<string>` 保持有序 URI；
  `isOriginalPhoto: boolean` 自 since 10 起声明，默认 `false`，`true` 才表示原始媒体。
- 原缺口：生产 caller 只使用 `Array.from(result.photoUris)`，未检查 `isOriginalPhoto`；
  默认 false 或系统转换结果可能进入 Phase 282 的 original photo ingress。
- 修复：成功选择后显式要求 `isOriginalPhoto === true`，否则抛出 fail-closed 错误；
  上限常量改为 `ORIGINAL_PHOTO_PICKER_MAX_SELECTION = 500`，行为不变且可回放锁定。
- 相邻边界：空列表/取消仍由 `validateOriginalPhotoSelection()` 拒绝；100 MiB、扩展名 allowlist、
  大图规范化、来源页上下文和 durable 插入不变。
- 结论：本阶段不宣称设备 picker 行为已验收，但静态生产路径不再把非原始资产误标为 original photo。
