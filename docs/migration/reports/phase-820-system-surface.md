# Phase 820 — 系统表面闭合：通知渠道 + 启动器图标分层

## 范围

原版系统级表面清单审计：通知渠道、启动器图标分层、widget 刷新触发器；
双端映射与 fail-closed 登记。

## 原版证据

### 通知渠道（1.0.3 = 1.4.2，零版本差）

应用级 2 个：`notability_recording`（`RecordingForegroundService`，IMPORTANCE_LOW，
名称取自 `feature_note_toolbox__recording_notification_channel_name`）与
`AudioCapture channel`（`AudioCaptureService`，IMPORTANCE_DEFAULT）。
厂商级 2 个：GMS availability、playcore assetpacks。
两个应用级渠道均为前台服务合规壳，非用户功能。

### 启动器图标（三层 adaptive icon）

- background：平铺向量 `#5497fe`（蓝）。
- foreground：铅笔 app-mark 向量，`#ff8e4d`（橙体）+`#f5ebd9`（米尖）+ 黑色。
- monochrome：`pathData="@string/ui_designsystem__app_mark_path"`，
  复用 Phase 812 登记的共享 app-mark 字符串。

## Harmony 映射

- 录音渠道 → `backgroundTaskManager` 的 `AUDIO_RECORDING` 连续长时任务
  （`OriginalRecordingSourceBackend.ets`），系统管理通知卡片；
  Harmony 无应用级渠道 API，渠道粒度 fail-closed。
- `layered_image` 两层 PNG：蓝渐变背景（#2C79F4→深 #1664F6 族）+
  白色方圆角栅格前景（394,260 不透明像素实测）。色相族一致、标记为
  NotaHarmony 品牌图形（与身份分叉登记一致）。
- monochrome 层无 Harmony 通道 → fail-closed。
- widget `LOCALE_CHANGED` → Harmony 系统驱动的卡片重渲染，等价成立。

## 交付物

- 证据：`docs/migration/evidence/phase-820-system-surface.md`
- ADR：`docs/migration/adr/ADR-0764-system-surface.md`
- Replay：`docs/migration/replays/d02-system-surface.mjs`（10 项断言）

## 验证

- 新增 Replay：10/10 通过。
- 全量 Desktop Replay 693/693。
- clean/default 与 `note@ohosTest` HAP 构建成功。

## 下一步

系统表面闭合。后续候选轴：`res/values/public.xml` 公共资源声明、
混淆代码内联字符串池（intent extras / content URI authority）残留、
baseline.prof 热点方法级抽样。
