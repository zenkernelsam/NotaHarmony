# Phase 89 修复总结：原版 Recording 本地资产 Loader

## 本阶段目标

Phase 88 已能读取可见 Recording 并把资产分成 MISSING/PENDING/READY/FAILED，但 READY 当时只
表示数据库中存在匹配 metadata 和非空 `localPath`。本阶段关闭“数据库说可用，但文件已经丢失、
变成目录、为空或字节数不符”仍会进入播放器的缺口。

## 原版证据

- `f45` 把解析出的本地 `Uri` 与 `yjb` Recording 合成为 `hkb`；`vna.e()` 为每个可解析录音
  建立媒体项，解析失败会跳过并记录 media-item-count divergence。
- `uw7.B()` 按前面 Recording 的有效时长累计定位媒体索引，再 seek 当前媒体内偏移；`C/D/G`
  分别处理当前录音起点、总时间线起点和 completed 后重播。
- `hkb` 在 segments 为空时使用 recording start/end；非空时只取第一个 segment 计算有效时长。
  原版仍把完整 URI 交给 ExoPlayer，因此本阶段没有猜测多 segment 拼接或裁剪 UI。

## 已完成修复

- 新增 `OriginalRecordingAssetLoader`：非 READY 状态不会触碰文件系统；READY 必须有合法正整数
  metadata size 和非空路径。
- 文件以只读方式打开后，对同一个 FD 执行 `statSync`，要求是普通文件、实际大小大于零且与原版
  asset metadata 完全相等。任何失败统一降为 FAILED，不会把坏 FD 交给未来播放器。
- 新增 `OriginalRecordingAssetLease`，向 AVPlayer 暴露 `{fd, offset: 0, length}`，并显式、幂等地
  持有/关闭文件。未来播放器必须先 reset/release，再关闭 lease，避免提前关闭造成异步解码失败。
- 新增 ArkTS 测试、ADR-0066 和 replay。没有虚报 codec、声音输出、seek、波形、录音采集或 UI。

## 验证结果

- 专项 replay：`recordingAsset=fd-lease-open-stat-exact-size`。
- 全量桌面 replay：`TOTAL=75 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`。仅有项目既有 deprecated/exception-handling warning。

## 后续边界

- 下一 Recording 子阶段需实现单 AVPlayer 状态机、generation 防快速切换串回调、completed 行为与
  页面退出 release；之后才接原版式列表/播放控制 UI。
- codec、真实时长、声音输出和 FD 生命周期仍需设备验收；原版 segments 的不一致边界不能靠猜测修正。
