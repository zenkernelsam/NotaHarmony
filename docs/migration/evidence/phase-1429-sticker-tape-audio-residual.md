# Phase 1429 证据：贴纸 / 胶带图案 / 录音音源残余轴收口

日期：2026-08-09
关联：ADR-1364；fixture `docs/migration/replays/d02-original-sticker-tape-audio-residual.mjs`（10 项）。

## 范围

`strings.xml` 前缀扫描最后三个未裁决簇：

| 前缀 | 键数 | 结论 |
|------|------|------|
| `feature_note_stickers__*` | 76 | fail-closed（STICKERS 特性位 InternalUserOnly + 包体 CDN 下载） |
| `ui_tools__tape_pattern_*` | 9 | 已移植（TapePattern 9/9 + picker + 持久化 + REVIEW 工具下发） |
| `recording_audio_source_*` + `select_audio_source` + `audio_*` | ~7 | 已移植（isStreamActive 门 + MIC/DEVICE_ONLY 对话框） |

## 一、贴纸系统：双重 fail-closed

### 特性位证据

`sources/defpackage/h35.java:299`：

```java
h35Var47 = new h35("STICKERS", 46, new rd5(null), null);
z0 = h35Var47;
```

`sources/defpackage/rd5.java`：

```java
public final class rd5 extends tee {
    public String toString() {
        return "InternalUserOnly(futureRemoteKey=" + this.k + ")";
    }
}
```

`sources/defpackage/h45.java:58` — `rd5` 实例仅在 `ra1.a()`（内部构建）
或远程 flag map 命中时返真；1.4.2 生产构建 `STICKERS` 恒为 off。
同门禁先例：`h35.y0` = NOTE_CONTENT_MANAGER_CREATE_TEMPLATE
（同 `rd5` 构造，Phase 1427 已裁决 fail-closed）。

### 门控消费点

- `urf.java:411,415,426`：`wqf.T`（SAVE_AS_STICKER 选单项）先经
  `h45.b(h35.z0)`，生产构建不可达。
- `d6b.java:1503`：同位 `h45.b(h35.z0)` 门（贴纸宿主面）。
- `dg2.java`：贴纸托盘行（show_all/insert/delete/delete_message）。
- `uxm.java`：Recents/Favorites/My Stickers 三空态文案页。

### 内容供给证据

`g2.java:556`：

```java
String strR = bm1.r("https://android-assets.notability.com/stickers/1.1.0/",
    cwgVar.a, ".zip");
```

`dwg.java:14` 枚举 39 个 `*_sticker_pack` 包名；下载走
`StickerPackDownloadWorker` / `StickerPackPrefetchWorker`
（WorkManager，`k4a.java:115-123`）。APK `assets/`、`res/` 内
无任何贴纸位图（仅 `assets/covers/stickers.pdf` 笔记封面，
已由 NoteCoverCatalog 移植）。

### 裁决

- 未发布特性（InternalUserOnly）→ 不虚构宿主面。
- 包体远端下载（CDN）→ 无法物化资产，fail-closed。
- `save_as_sticker`（选单 case14）同样挂在 STICKERS 位之后，
  生产不可达 → 不实现。
- `note_cover_preset_stickers` 封面预设与贴纸功能无关，已移植保留。

## 二、胶带图案：9/9 精确等价

原版 `brh.java:251-279` — `xqh` 枚举 ordinal→drawable：

| ordinal | 原版 | drawable | Harmony `TapePattern` |
|---------|------|----------|------------------------|
| 0 | stripes | tape_pattern_stripes | `STRIPES = 0` |
| 1 | grid | tape_pattern_grid | `GRID = 1` |
| 2 | dots | tape_pattern_dots | `DOTS = 2` |
| 3 | plain | **null**（无图案图标） | `PLAIN = 3` |
| 4 | stars | tape_pattern_stars | `STARS = 4` |
| 5 | flowers | tape_pattern_flowers | `FLOWERS = 5` |
| 6 | hearts | tape_pattern_hearts | `HEARTS = 6` |
| 7 | waves | tape_pattern_waves | `WAVES = 7` |
| 8 | checkers | tape_pattern_checkers | `CHECKERS = 8` |

Harmony 侧通路：`TapePattern`（`StrokeTypes.ets:86-96`）逐序等价；
`TapePatternPicker`（`ui/editor/TapePatternPicker.ets`，9 枚
swatch 网格 + `tape_patterns` 标题）挂 `ToolboxSettingsDialog:196`；
`EditorViewModel.setToolTapePattern` 校验 + `ToolStateEntity.
tapePattern` 持久化 + `currentTool === REVIEW` 时随 CreateInkOp
下发（`dm2` 等价，`EditorViewModel.ets:233-235`）。
**无缺口。**

## 三、录音音源选择：已移植

原版 `f9e.java` `A(b9e)`（OnStartRecordingClick(source=MIC)）：

```java
if (!((AudioManager) getSystemService("audio")).isMusicActive()) {
    baeVar.y(j9e.MIC, bpjVar);   // 无音乐播放：直接 MIC 录
    return;
}
ptgVar.l(null, Boolean.TRUE);    // 有音乐：弹 source picker
```

`j9e` 枚举：`MIC`（recording_audio_source_microphone）/
`DEVICE_ONLY`（recording_audio_source_internal）。
`ec2.java:1035` 对话框标题 `select_audio_source`。

Harmony `NotePage.ets:1363-1390`：`audio.getAudioManager().
getStreamManager().isStreamActive(STREAM_USAGE_MUSIC)` 门 →
`promptAction.showDialog`（select_audio_source 标题 +
microphone/internal 双钮）→ `session.start(OriginalRecordingAudioSource.
MICROPHONE | DEVICE_ONLY)`；`OriginalRecordingSourceBackend.ets:29,111`
按 source 切换采集通路。**无缺口。**
