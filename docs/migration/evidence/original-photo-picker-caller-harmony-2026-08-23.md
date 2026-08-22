# Phase 283 Harmony PhotoViewPicker Caller 平台证据（2026-08-23）

来源为本地 DevEco SDK 与正式仓当前源码；未读取或修改 Desktop 之外的逆向工作树。

## 1. 本地 API 声明

`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.file.photoAccessHelper.d.ts`

- `photoAccessHelper.PhotoViewPicker.select(option?): Promise<PhotoSelectResult>`；
- `PhotoSelectOptions.MIMEType: PhotoViewMIMETypes`；
- `PhotoViewMIMETypes.IMAGE_TYPE = 'image/*'`；
- `PhotoSelectResult.photoUris: Array<string>`；
- 本地声明中 `PhotoViewPicker` 构造器不接受 `Context`，因此生产代码使用无参构造；
- `@ohos.file.picker.d.ts` 中的同名 API 已标记 deprecated，本阶段改用 MediaLibraryKit 的现行导出。

`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\kits\@kit.CoreFileKit.d.ts`
只导出旧 `picker`；`@kit.MediaLibraryKit.d.ts` 导出 `photoAccessHelper`。因此 caller 的 import 来自
MediaLibraryKit，CoreFileKit 继续只提供 `fileIo`。

## 2. 正式仓接线

- `EditorToolbar.ets`：新增 Photo 按钮和 compact 菜单项。
- `NotePage.ets`：`onInsertPhotos()` 递增 `photoInsertSignal` 并传给画布。
- `NoteCanvasView.ets`：
  - watcher 调用 `startOriginalPhotoInsert()`；
  - `photoImportBusy` 防止并发选择/导入；
  - `pickAndImportOriginalPhotos()` 使用 UIAbility context 与 cacheDir；
  - ingress 输出按顺序转为 image persistence plan；
  - 循环调用既有 durable `commitOriginalImageInsert()`；
  - 成功后合并最终 images、element order、selection、undo history 和 render。

## 3. 行为边界

- Phase 282 已固定 URI list all-or-nothing 校验；caller 在 import 前再次执行同一校验。
- 多张图片按输入顺序插入，anchor 逐张偏移 24 页面单位。
- 单图持久化保持原版原子事务；多图批次没有跨张数据库事务，失败语义在 ADR-0261 中显式记录，
  不冒充整批 all-or-nothing。
- 真实系统 picker 只能在设备上验证；本阶段不启动模拟器、虚拟机、真机或 Hypium。

## 4. 验证

- ArkTS fixture：ingress 与 picker caller 均注册到测试套件。
- 专项 Replay：`D02_ORIGINAL_PHOTO_PICKER_CALLER_OK TOTAL=11 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=268 FAILED=0`。
- clean 后串行双 HAP 成功；unsigned HAP 为 6,490,335 与 26,069,585 bytes。
