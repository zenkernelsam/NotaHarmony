# ADR-1364：贴纸 / 胶带图案 / 录音音源残余簇裁决

- 状态：Accepted
- 关联：ADR-1362（strings.xml 前缀扫描收口）、ADR-1363
  （Manifest+残余资源轴）、ADR-0046（笔刷渲染边界先例）、
  evidence `phase-1429-sticker-tape-audio-residual.md`、
  fixture `d02-original-sticker-tape-audio-residual.mjs`

## 背景

`strings.xml` 前缀扫描末端三簇未裁决：`feature_note_stickers__*`
（76 键）、`ui_tools__tape_pattern_*`（9 键）、
`recording_audio_source_*`/`select_audio_source`/`audio_*`（约 7 键）。

## 决定

### 一、贴纸系统：fail-closed（双重边界）

1. **未发布特性**：`h35.z0` = `STICKERS` 位以 `new rd5(null)`
   构造 —— `rd5` 即 `InternalUserOnly`（toString 直证）。
   `h45.b()` 在生产构建恒返 false：
   - 选单 `SAVE_AS_STICKER`（`wqf.T`）在 `urf.java:411` 被
     `h45.b(h35.z0)` 短路；
   - 贴纸托盘（`dg2`/`uxm`/`d6b.java:1503`）同位门控。
   与 `NOTE_CONTENT_MANAGER_CREATE_TEMPLATE`（`h35.y0`，同 `rd5`）
   先例一致 —— 1.4.2 未发布，不虚构宿主。
2. **包体远端依赖**：39 个命名包经
   `android-assets.notability.com/stickers/1.1.0/<pack>.zip`
   由 `StickerPackDownloadWorker`/`StickerPackPrefetchWorker`
   下载；APK 无贴纸资产。移植需引入不可复刻的版权内容 CDN →
   fail-closed。
3. 名称近似但无关的 `note_cover_preset_stickers`（笔记封面预设）
   已按 ADR-1341 通路移植，不属本裁决范围。

### 二、胶带图案：已移植，无缺口

`xqh` 枚举序 STRIPES/GRID/DOTS/PLAIN(无图标)/STARS/FLOWERS/
HEARTS/WAVES/CHECKERS（`brh.java:251-279`，case3 返 null）与
Harmony `TapePattern` 0..8 逐位等价；`TapePatternPicker` +
`ToolStateEntity.tapePattern` + REVIEW 工具 `CreateInkOp` 下发
（`dm2` 等价）全通。

### 三、录音音源选择：已移植，无缺口

`f9e.A(b9e)` = `isMusicActive()` 假→MIC 直录、真→
`select_audio_source` picker（MIC/DEVICE_ONLY）。Harmony
`NotePage.ets:1363-1390` 以 `isStreamActive(STREAM_USAGE_MUSIC)`
+ `showDialog` + `OriginalRecordingAudioSource` 逐语义等价。

## 后果

- `feature_note_stickers__*` 全部 76 键 fail-closed（未发布 +
  CDN），不进入 Harmony 资源表。
- 胶带/音源簇判定为已完成移植，fixture 固化不变量防回归。
- `strings.xml` 前缀扫描至此全域收口。
