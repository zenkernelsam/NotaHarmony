# Harmony 证据：原版 "Take Photo" 拍照入库 — 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）编辑器插入菜单中的
"Take Photo" 项，补齐 Harmony 缺失的拍照入库入口：菜单点击 → 相机拍摄 →
走既有原版照片归一化/持久化管线入库，共享 photo-ingress 租约语义。

## 原版证据

### 插入菜单项（qc.java / kkf.java）

- `resources/res/values/strings.xml:606`：
  `feature_note_toolbox__take_photo` —— 菜单文案真实存在。
- `defpackage/qc.java`：插入菜单按序装载
  Add Files → Add Photo → **Take Photo** → Add GIF → Insert Math；
  `R.drawable.ui_designsystem__camera_outline` 图标 +
  `new sc(function3, function1, 2)` 将 Take Photo 绑定到菜单槽位 function3。
- `defpackage/kkf.java:598`：宿主以
  `new qc(function0, function5, function1, function2, function4, function3, 0)`
  装配六槽菜单——Take Photo 是真实接线项，非死 UI。

### 拍照契约（f35.java）

- `f35.java:64`：相机入口构造 `android.media.action.IMAGE_CAPTURE` intent，
  `putExtra("output", uri)` 指定应用侧输出 URI，
  `addFlags(1).addFlags(2)` 授予读写——**原版语义：相机把照片写到应用提供的
  URI，随后该 URI 走统一入库管线**（与 Add Photo 同管线的校验/归一化/落盘）。

## Harmony 落点

### 相机调用（OriginalCameraPickerCaller.ets，新文件）

- `cameraPicker.pick(context, PickerMediaType.PHOTO, CAMERA_POSITION_BACK)`
  —— Harmony 等价物：系统相机写入并由 PickerResult 直接返回产出 URI，
  与原版 IMAGE_CAPTURE + EXTRA_OUTPUT 语义一致（都落在"应用侧 URI 再入库"）。
- 取消/失败契约：`resultCode !== 0 || resultUri === ''` → `''` → `[]`
  —— 与照片选择器相同的空列表静默返回约定。
- `isValidOriginalPhotoUri(uri)` 守卫 + `importOriginalPhotos([uri], cacheDir)`
  —— **复用同一归一化管线**，无独立拍照持久化旁路。
- `setOriginalCameraUriCapturerForTest`/`resetOriginalCameraUriCapturerForTest`
  测试缝（与 `OriginalPhotoPickerCaller` 的 seam 模式一致）。

### 画布入口（NoteCanvasView.ets）

- `@Prop @Watch('onCameraCaptureSignalChange') cameraCaptureSignal` ——
  与 `photoInsertSignal` 相同的信号驱动模式。
- `startOriginalCameraCapture()` 镜像 `startOriginalPhotoInsert()`：
  `canStartOriginalPhotoInsert()` 生命周期/页面身份门 →
  `photoImportBusy = true` → `getOriginalPhotoInsertOrigin()` 捕获
  generation/pageId 原点 → `captureAndImportOriginalPhoto()` →
  `isPhotoContextCurrent` 过期页守卫 → `commitOriginalPhotoInsert()` →
  部分失败 toast 绑定原点页 → `finally { photoImportBusy = false;
  onPhotoIngressFinished(); }`（取消/失败/异常均释放租约）。

### 页面与工具栏（NotePage.ets / EditorToolbar.ets）

- `NotePage.onTakePhoto`：`photoImportLeaseActive || pageOperationBusy ||
  historyPending || pageStructureLeaseActive` 四条件拦截 →
  `photoImportLeaseActive = true` → `cameraCaptureSignal++`；
  画布 `onPhotoIngressFinished` 回调释放租约——与 onInsertPhotos 同一租约，
  拍照期间页操作/历史/结构操作全部互斥。
- `EditorToolbar`：完整工具栏在 Add Photo 与 Insert Math 之间新增
  Take Photo 按钮；紧凑插入菜单同位插入——保持原版 qc.java 菜单顺序。
  两处均带 `photoImportLeaseActive` 禁用/拦截守卫。
- 资源：`take_photo`（base: "Take Photo" / zh_CN: "拍照"），
  沿用原版字符串键位命名风格。

## 适配差异登记

- 原版 `IMAGE_CAPTURE + EXTRA_OUTPUT`：应用先造 URI 再交给相机写。
  Harmony `cameraPicker.pick`：系统相机内部管理产出，直接返回 URI。
  两者在"得到一个待入库的图片 URI"上等价；归一化/锚点/落盘全部复用同一管线。
- 原版无单独相机权限申请代码（intent 委托给系统相机应用）；
  Harmony cameraPicker 同样为系统组件托管，无需 ohos.permission.CAMERA。

## 验证

- `docs/migration/replays/d02-original-take-photo-ingress.mjs`：
  27 项断言（原版 qc/f35/kkf/strings 锚点 + Harmony 调用/信号/租约/
  管线复用锚点 + 取消→空与租约互斥可执行模型）全部通过。
- `d02-photo-import-page-operation-lease.mjs`：`onPhotoIngressFinished`
  计数锚点 2→3 + camera 入口加入租约释放循环（第三条入库入口的合法扩展）。
- 函数落位调整：`startOriginalCameraCapture` 置于
  `insertOriginalPhotos`/`confirmMathInsert` 之间，避开四个既有
  replay 的按位置切片计数锚点（isPhotoContextCurrent 次数等回归针）。
- 全量 replay：430/430；`note@default` + `note@ohosTest` HAP 构建 0 错误。
