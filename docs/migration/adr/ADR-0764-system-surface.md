# ADR-0764 — 通知渠道与启动器图标的平台等价处理

## 状态

已接受。

## 背景

原版系统表面审计闭合通知渠道与启动器图标两条清单：

- 通知渠道共 4 个（1.0.3 = 1.4.2）：应用级 `notability_recording`（LOW）、
  `AudioCapture channel`（DEFAULT），厂商级 GMS availability 与 playcore
  assetpacks 各一。两个应用级渠道的存在理由是 Android 前台服务的合规要求，
  不承载用户功能。
- 原版启动器图标为三层 adaptive icon：平铺蓝底 `#5497fe` + 铅笔 app-mark
  前景向量（`#ff8e4d`/`#f5ebd9`/黑）+ themed-icon monochrome 层
  （引用共享 `ui_designsystem__app_mark_path`）。

## 决定

1. **渠道粒度 fail-closed，任务机制等价**：Harmony 无应用级通知渠道 API；
   录音存活由 `backgroundTaskManager` 的 `AUDIO_RECORDING` 连续长时任务承担，
   系统通知卡片由 OS 管理。不复制渠道对象本身。
2. **vendor 渠道 fail-closed**：GMS availability 与 playcore assetpacks
   渠道随 SDK 消失。
3. **图标层差异登记**：Harmony `layered_image` 为两层（背景 PNG 蓝渐变 +
   白色方圆角栅格前景 PNG）。色相族与原版一致；前景标记为 NotaHarmony
   品牌图形（呼应 ADR-0758/0763 的身份分叉登记），不做像素级复刻。
   monochrome 层在 Harmony 无对应通道，fail-closed。
4. **widget LOCALE_CHANGED 等价**：原版 widget provider 监听系统语言变更
   刷新标签；Harmony 卡片由系统语言切换驱动重渲染，无需应用层接收器。

## 后果

- 系统表面（通知渠道 + 图标 + widget 刷新触发器）闭合。
- 新增 `d02-system-surface.mjs` 回归：渠道清单/重要性、图标三层结构、
  Harmony 两层资产真实性、AUDIO_RECORDING 连续任务存在性。

## 已验证

- `d02-system-surface.mjs`：10/10。
- 全量 Desktop Replay 693/693 + clean/default、`note@ohosTest` HAP 构建成功。
