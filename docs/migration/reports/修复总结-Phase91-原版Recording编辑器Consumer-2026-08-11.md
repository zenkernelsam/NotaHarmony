# Phase 91 修复总结：原版 Recording 编辑器 Consumer

## 原版证据

原版 `n05` 在笔记 toolbox 中显示有界 Recording 列表，行内包含播放控制、名称与时间信息；`f74`
明确规定：点击当前录音切换播放/暂停，点击其他录音选择该索引。`kpa` 同时携带播放状态、当前索引、
累计时间和录音边界，说明录音 consumer 属于编辑器工作流，而不是独立设置页。

## 已完成修复

- 新增 `RecordingPanel`，在编辑器工具栏下提供 220vp 有界列表、当前项高亮、播放/暂停、进度 slider、
  elapsed/total 时间和关闭控制。MISSING/PENDING/FAILED 资产不可播放并显示明确状态。
- `NotePage` 在数据库初始化后读取 Phase 88 的可见 Recording，选择其他行会通过 Phase 89/90 loader
  与 controller 自动播放；当前播放行会暂停，paused/completed 可继续，失败项可重试加载。
- 页面订阅 `AssetAvailabilityHub`，录音 bytes 晚到时自动重新物化可用状态；退出时取消订阅并 release
  controller，确保先释放 AVPlayer 再由 lease 关闭 FD。初始查询与资产到达查询使用 generation，旧
  PENDING 结果不能覆盖后返回的新 READY snapshot。
- Recording 读取失败被隔离在面板内，不会把整篇笔记误判成打开失败，也不会清空页面内容。
- 新增基础英文资源与时间格式测试；没有虚报采集、删除/重命名、速度、波形、audio-ink 或跨录音自动切换。

## 边修边审新发现

Production UI 引用完整 Recording 链后，默认构建首次纳入此前只被 replay/test 间接覆盖的文件，暴露：

- `OriginalRecordingPlaybackController` 的 `ErrorCallback` 全局类型在生产模块不可见，现改为显式
  `(BusinessError) => void`。
- `OriginalRecordingOperation` 对任意 catch 值执行 `throw error`，违反 ArkTS；现保留专用 deferred
  分支，其余异常包装为标准 `Error`，不再改变 deferred 语义。

## 验证

- 专项 replay：`recordingEditor=list-select-toggle-seek-late-asset-release`。
- 全量桌面 replay：`TOTAL=77 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`。仅有项目既有 deprecated/exception-handling warning。
