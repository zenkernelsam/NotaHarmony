# Phase 1471 — 音频回放媒体键（f2 兜底链尾 → q5d.k.h/i/z）

- **阶段**: Phase 1471
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `NoteCanvasView.ets` `onCanvasKeyEvent` →
  `NotePage.ets` `onKeyRecordingSeekBy`/`onKeyRecordingPlayPause`

## 原版证据链

### 分发支（f2.java:265-340，`!rsi` 门内尾链）

```java
} else if (db8.r && db8.s && pa8.a(n, pa8.h)) {   // Ctrl+Shift+DPAD_RIGHT
    if (lxm.a(o,1)) q5dVar.k.h();
} else if (db8.r && db8.s && pa8.a(n, pa8.g)) {   // Ctrl+Shift+DPAD_LEFT
    if (lxm.a(o,1)) q5dVar.k.i();
} else if (db8.r || db8.q || db8.s || !pa8.a(n, pa8.M)) {
    // DPAD 微移支 / b2=0 透传
} else if (lxm.a(o, 1)) {
    q5dVar.k.z();                                  // 纯 SPACE UP
}
```

- `db8.q`=Alt、`r`=Ctrl、`s`=Shift（db8.java:1045-1056 `isAltPressed/
  isCtrlPressed/isShiftPressed`）。
- 修饰键匹配：seek 支 `r&&s`（alt 不限）；SPACE 支要求全无修饰。
- 均 UP 动作、DOWN 亦消费（支内无 `b2=0` 落点）。

### 语义（xke.java，`q5d.k` = xke byte29 包装 q5d 录制控制器）

```java
// h() — seek +10s
double pos = q5d.p.getValue();              // 累计播放位 ms
double t   = pos + 10000.0;
if (t <= q5d.q.getValue()) pos = t;         // clamp ≤ 总时长
w(pos);
// i() — seek −10s：max(pos−10000, 0) → w(d)
// w(d) — 累计位→录音索引：for i where q5d.d(i)<=d; pv4.z(i, d−d(i))
//        跨录音 seek + q5d.p 累计位更新
// z() — m==e6d.F(PLAYING) → C()（pv4.u() 暂停；PAUSED/无 player no-op）
//        否则 → D()（列表空 log+no-op；非 PLAYING → pv4.v() 播放当前）
```

- `e6d` = {F:PLAYING, G:PAUSED, H:STOPPED}。
- `q5d.p` = 累计时间轴播放位（多录音串接），`q5d.q` = 总时长。

## Harmony 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_SPACE=2050`、
  `ORIGIN_RECORDING_SEEK_STEP_MS=10000`。
- `NoteCanvasView` 新增回调 prop：`onKeyRecordingSeekBy(deltaMs)`、
  `onKeyRecordingPlayPause()`；`onCanvasKeyEvent` `!textEditing` 块尾部
  新增两支（Ctrl+Shift+←/→ 与纯 SPACE），UP 动作、双向消费。
- `NotePage` 接线：
  - seek：`target = clamp(playbackCumulativePositionMs+delta, 0,
    playbackCumulativeDurationMs)` → `seekRecordingTimeline(target)`
    ——累计时间轴定位与 `xke.w(d)`（分段偏移→单曲索引+局部 ms）等价。
  - toggle：`playbackSnapshot.recordingId ?? 首条可见录音` →
    `toggleRecording(id)`——PLAYING→pause / 非 PLAYING→play 与
    `z()` 同核；空列表 → no-op（`D()` 空表 log+return 等价）。

## 差异与边界

- 原版 `h()` 内部还有 `sgn.R(scope)`/`q7d!=null` 活性门；Harmony 由
  `seekRecordingTimeline` 内 `locateOriginalRecordingTimeline` 空表
  防御等价（总时长≤0 直接返回）。
- `D()` 播放的是"当前 q7d"（上次加载的录音）；Harmony 取
  `playbackSnapshot.recordingId`（即当前）或首条可见——首次播放时
  原版 `q5d.b()` 的默认 player 行为未完全解码，登记为首条近似。
- `D()` 内 `q5d.g==1` 时 `pv4.w()`、`==4` 时 `y()` 的辅助路径
  （可能为倍速/起始位置重置）未逐支复刻——`toggleRecording` 的
  load+play 语义覆盖主路径。

## 验证

- `d02-original-media-keys.mjs`：20 项——常量 pin、prop 声明、
  分发门控（修饰键/UP/消费）、链序、NotePage 钳制与切换接线、
  可执行模型（h/i 钳制 4 例 + z 状态机 3 例）。
- `note@default` 构建通过；全量基线与 `note@ohosTest` 收尾验证。
