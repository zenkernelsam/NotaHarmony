# 原版 audio-ink tap-to-seek（h3 case28）证据链（JADX, decompiled_1.0.3）

日期：2026-09-25。来源：`decompiled_1.0.3` JADX 输出。

## 结论

原版播放录音时，**点按画布上与录音联动的笔触（audio-linked ink）
会把播放进度跳到该笔触书写时刻**（"tap a word to hear that moment"）。
Harmony 此前只移植了反向（播放驱动笔触出现动画，
`OriginalAudioLinkedInkPlayback`/`s1j` 同义），缺点按寻址方向。
本阶段补齐。

## 原版消费链

`h3.java` case 28（画布点按分发 lambda，约 320-395 行）：

1. `trb.e(fsb.c)`（`fsb` 远程键 `androidAudioInkSync`，打包默认
   `true`）为 FALSE → `audio_ink_sync.tap_null_flag_off` 返回。
2. 播放状态 `((vna)b40.L).r.I` != `joa.I`（PLAYING）→
   `tap_null_not_playing` 返回。**仅播放中生效**。
3. `((fvb)b40.J).c()` 当前笔记会话空 → `tap_null_no_note`。
4. `((sia)((a79)x09).J.I).b()` 笔记无录音 → `tap_null_no_recordings`。
5. `((fu1)b40.K).e(jE, x09, null)` 点命中测试（jE = `i3a.e(oqa.c)`
   的页坐标）→ null → `tap_null_no_hit`。
6. `vndVarE.I instanceof bf0`（audio-linked 元素类）非 →
   `tap_null_not_audio_linked`。
7. `vv7.S(bf0Var.c(), vv7.N(x09))` 折回 → `playback.relative_ms`
   毫秒 → `tap_seek` 上报 + 返回 seek Function0（消费本次点按）。

## `vv7` 折回语义

- `vv7.N(x09)`（407-425）：`bja` 录音表取值 → `xj2.f(id, cl2.I)`
  剔除删除标记 → `au1.K1` 排序（`zp9(13)` 起始序）→ `yjb.L()`
  逐录音段表扁平化 → 全局排序生效段列表。
- `vv7.S(j, list)`（508-528）：逐段 `jC = c-d` 钳位 ≥0 累计；
  `j` 落入 `[d,c]`（两端含，`njj.h0` 无符号比较）→ 返回
  `累计 + max(0, j-d)`；全部落空 → **null**（点按不产生 seek）。

## Harmony 落点

- `OriginalAudioLinkedInkPlayback.resolveOriginalAudioInkSeekTarget`：
  新增 `vv7.S` 逐段累计语义；按 `OriginalAudioSeekRecording[]`
  （recordingId + 生效段）返回 `{recordingId, localPositionMs}` —
  本地播放位天然跳过多录音基差。
- `NoteCanvasView.trySeekAudioLinkedInkAt`：DEFAULT 工具点按分发中
  `topmostPageElementIdAt`（= `fu1.e` 两程命中 + 5 页单位容差）命中
  顶元素须为带 `audioStartTime` 的 STROKE（bf0 等价）；命中即
  `onAudioInkSeekTap` 上抛 + 消费点按（`isDrawing=true` 阻断后续
  选区/文本分发）。tape 揭示判定在先（dl1 case2 先行语义不变）。
- `NotePage`：`audioSeekRecordings` 与 `audioPlaybackSegments` 同源
  重建（visiblePlaybackRecordings ≈ vv7.N 的未删除过滤）；
  `playbackIsPlaying` prop 接 `snapshot.state==PLAYING`（= joa.I）；
  回调按 `timelinePositionForRecording`→`seekRecordingTimeline`
  落地（与既有 RecordingPanel seek 同链，含跨录音 load+resume），
  受 photoImport/pageStructure 租约保护，timeline 外 id 防御丢弃。
- 旗标默认 `true` → 无条件生效（与打包默认一致）。

## 记录在案的偏差

- 原版 h3 在点按手势确认时触发；Harmony 在 DEFAULT 工具 Down 分发
  触发（与现有 applyTapSelect 的 Down 提交约定一致）。Down 后转
  为平移拖拽时原版不 seek（手势未成 tap）而 Harmony 已先行 seek —
  触发时点差，判定为可接受的等价偏差。
- 非 DEFAULT 工具（书写/橡皮/选区）的点按继续走原绘制路径不 seek；
  原版 h3 在全局点按拦截层生效与否静态不可完全判定，按"不改变
  绘制工具行为"保守移植并登记。
