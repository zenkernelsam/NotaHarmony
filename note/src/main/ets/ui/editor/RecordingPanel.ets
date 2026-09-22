import {
  OriginalRecordingPlaybackSnapshot, OriginalRecordingPlaybackSpeed,
  OriginalRecordingPlaybackState,
} from '../../core/adaptation/OriginalRecordingPlaybackController';
import { OriginalRecordingCaptureState } from
  '../../core/adaptation/OriginalRecordingCaptureController';
import {
  OriginalRecordingSessionFailure, OriginalRecordingSessionSnapshot,
} from '../../core/adaptation/OriginalRecordingSessionController';
import {
  buildOriginalRecordingPresentation, OriginalRecordingPresentation,
} from '../../core/adaptation/OriginalRecordingPresentation';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../../data/OriginalRecordingStore';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';

const ORIGINAL_RECORDING_SKIP_MS: number = 10000;  // 原版 uw7.r/s ±10000ms

@Component
export struct RecordingPanel {
  @Prop recordings: MaterializedOriginalRecording[] = [];
  @Prop loading: boolean = false;
  @Prop snapshot: OriginalRecordingPlaybackSnapshot = {
    state: OriginalRecordingPlaybackState.IDLE, recordingId: null,
    positionMs: 0, durationMs: 0, error: null,
  };
  @Prop cumulativePositionMs: number = 0;
  @Prop cumulativeDurationMs: number = 0;
  @Prop playbackSpeed: OriginalRecordingPlaybackSpeed = OriginalRecordingPlaybackSpeed.SPEED_1_0;
  @Prop pendingDeleteIds: string[] = [];
  @Prop photoImportLeaseActive: boolean = false;
  @Prop captureSnapshot: OriginalRecordingSessionSnapshot = {
    captureState: OriginalRecordingCaptureState.IDLE, elapsedMs: 0,
    preparing: false, saving: false,
    failure: OriginalRecordingSessionFailure.NONE, failureSequence: 0,
  };
  @Prop capturePauseSupported: boolean = true;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onToggle: (recordingId: string) => void = () => {};
  onSeek: (positionMs: number) => void = () => {};
  onSpeedChange: (speed: OriginalRecordingPlaybackSpeed) => void = () => {};
  onDelete: (recordingId: string) => void = () => {};
  onUndoDelete: (recordingId: string) => void = () => {};
  onRecord: () => void = () => {};
  onPauseCapture: () => void = () => {};
  onResumeCapture: () => void = () => {};
  onStopCapture: () => void = () => {};
  onClose: () => void = () => {};

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.recordings'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
        if (this.loading) {
          LoadingProgress().width(18).height(18).margin({ left: 8 })
        }
        Blank()
        Button('×')
          .width(36).height(32).fontSize(20)
          .backgroundColor(Color.Transparent)
          .fontColor(this.resolveTokens().textPrimary)
          .accessibilityText($r('app.string.close_recordings'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.onClose();
          })
      }
      .width('100%').height(40).padding({ left: 12, right: 8 })

      this.CaptureControls()

      if (!this.loading && this.recordings.length === 0) {
        Text($r('app.string.no_recordings'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textSecondary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.recordings, (recording: MaterializedOriginalRecording, index: number) => {
            ListItem() {
              if (this.isPendingDelete(recording.id)) {
                this.PendingDeleteRow(recording)
              } else {
                this.RecordingRow(recording, index)
              }
            }
          }, (recording: MaterializedOriginalRecording): string => recording.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: this.resolveTokens().border, startMargin: 56 })
      }

      this.PlaybackControls()
    }
    .width('100%').height(320)
    .backgroundColor(this.resolveTokens().surface)
    .border({ width: { top: 1, bottom: 1 }, color: this.resolveTokens().border })
  }

  @Builder
  private PlaybackControls() {
    Column() {
      if (shouldShowRecordingTimeline(this.snapshot.recordingId)) {
        Column() {
          if (this.cumulativeDurationMs <= 0) {
            // 原版 faj：播放数据为空（jpa.a）时显示占位文案而非控件。
            Text($r('app.string.no_playback_data_available'))
              .fontSize(12)
              .fontColor(this.resolveTokens().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
          } else {
            Slider({ value: this.cumulativePositionMs, min: 0,
              max: Math.max(1, this.cumulativeDurationMs), step: 1 })
              .width('100%')
              .enabled(this.controlsEnabled && this.canSeek())
              .opacity(this.controlsEnabled && this.canSeek() ? 1 : 0.45)
              .selectedColor(this.resolveTokens().accent)
              .onChange((value: number) => {
                if (this.photoImportLeaseActive || this.loading) {
                  return;
                }
                this.onSeek(value);
              })
            Row() {
              Text(formatRecordingTime(this.cumulativePositionMs))
                .fontSize(11).fontColor(this.resolveTokens().textSecondary)
              Blank()
              // 原版 d32 case 6/7：快退/快进 10 秒（uw7.s/r 语义）
              this.SkipButton(-ORIGINAL_RECORDING_SKIP_MS,
                $r('app.string.recording_rewind_10_seconds'), '↺ 10s')
              this.SkipButton(ORIGINAL_RECORDING_SKIP_MS,
                $r('app.string.recording_forward_10_seconds'), '10s ↻')
              Blank()
              Text(formatRecordingTime(this.cumulativeDurationMs))
                .fontSize(11).fontColor(this.resolveTokens().textSecondary)
            }
            .width('100%')
          }
        }
        .height(48)
      }
      Row() {
        Text($r('app.string.recording_playback_speed'))
          .fontSize(12)
          .fontColor(this.resolveTokens().textSecondary)
        Blank()
        this.SpeedButton('1x', OriginalRecordingPlaybackSpeed.SPEED_1_0)
        this.SpeedButton('1.5x', OriginalRecordingPlaybackSpeed.SPEED_1_5)
        this.SpeedButton('2x', OriginalRecordingPlaybackSpeed.SPEED_2_0)
      }
      .width('100%').height(40)
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .border({ width: { top: 1 }, color: this.resolveTokens().border })
  }

  @Builder
  private CaptureControls() {
    Row() {
      if (this.captureSnapshot.preparing || this.captureSnapshot.saving) {
        LoadingProgress().width(20).height(20)
        Text(this.captureSnapshot.saving ? $r('app.string.saving_recording') :
          $r('app.string.preparing_recording'))
          .fontSize(13)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ left: 10 })
      } else if (this.isCapturing()) {
        Text(formatRecordingTime(this.captureSnapshot.elapsedMs))
          .width(64)
          .fontSize(14)
          .fontColor(this.resolveTokens().textPrimary)
        if (this.captureSnapshot.captureState === OriginalRecordingCaptureState.RECORDING) {
          if (this.capturePauseSupported) {
            Button($r('app.string.pause_recording'))
              .height(34).fontSize(12).borderRadius(4)
              .enabled(this.controlsEnabled)
              .backgroundColor(this.resolveTokens().control)
              .fontColor(this.resolveTokens().textPrimary)
              .onClick(() => {
                if (this.photoImportLeaseActive || this.loading) {
                  return;
                }
                this.onPauseCapture();
              })
          }
        } else if (this.captureSnapshot.captureState === OriginalRecordingCaptureState.PAUSED) {
          Button($r('app.string.resume_recording'))
            .height(34).fontSize(12).borderRadius(4)
            .enabled(this.controlsEnabled)
            .backgroundColor(this.resolveTokens().control)
            .fontColor(this.resolveTokens().textPrimary)
            .onClick(() => {
              if (this.photoImportLeaseActive || this.loading) {
                return;
              }
              this.onResumeCapture();
            })
        }
        Blank()
        Button($r('app.string.stop_recording'))
          .height(34).fontSize(12).borderRadius(4)
          .enabled(this.controlsEnabled &&
            (this.captureSnapshot.captureState === OriginalRecordingCaptureState.RECORDING ||
              this.captureSnapshot.captureState === OriginalRecordingCaptureState.PAUSED))
          .backgroundColor(this.resolveTokens().danger)
          .fontColor(this.resolveTokens().onAccent)
          .onClick(() => {
            if (this.photoImportLeaseActive || this.loading) {
              return;
            }
            this.onStopCapture();
          })
      } else {
        Button($r('app.string.start_recording'))
          .height(34).fontSize(13).borderRadius(4)
          .enabled(this.controlsEnabled)
          .backgroundColor(this.resolveTokens().accent)
          .fontColor(this.resolveTokens().onAccent)
          .onClick(() => {
            if (this.photoImportLeaseActive || this.loading) {
              return;
            }
            this.onRecord();
          })
      }
    }
    .width('100%').height(56).padding({ left: 12, right: 12 })
    .border({ width: { bottom: 1 }, color: this.resolveTokens().border })
  }

  private isCapturing(): boolean {
    const state: OriginalRecordingCaptureState = this.captureSnapshot.captureState;
    return state === OriginalRecordingCaptureState.STARTING ||
      state === OriginalRecordingCaptureState.RECORDING ||
      state === OriginalRecordingCaptureState.PAUSING ||
      state === OriginalRecordingCaptureState.PAUSED ||
      state === OriginalRecordingCaptureState.RESUMING ||
      state === OriginalRecordingCaptureState.STOPPING;
  }

  @Builder
  private SkipButton(deltaMs: number, a11y: Resource, label: string) {
    Button(label)
      .height(22).fontSize(11).borderRadius(4)
      .padding({ left: 6, right: 6 })
      .margin({ left: 2, right: 2 })
      .enabled(this.controlsEnabled && this.canSeek())
      .opacity(this.controlsEnabled && this.canSeek() ? 1 : 0.45)
      .backgroundColor(this.resolveTokens().control)
      .fontColor(this.resolveTokens().textPrimary)
      .accessibilityText(a11y)
      .onClick(() => {
        if (this.photoImportLeaseActive || this.loading) {
          return;
        }
        // 原版 uw7.s：rewind = max(pos - 10000, 0)；uw7.r：
        // forward = min(pos + 10000, duration)；合并为 clamp。
        const target: number = Math.max(0, Math.min(this.cumulativeDurationMs,
          this.cumulativePositionMs + deltaMs));
        this.onSeek(target);
      })
  }

  @Builder
  private SpeedButton(label: string, speed: OriginalRecordingPlaybackSpeed) {
    Button(label)
      .width(42).height(26).fontSize(11).borderRadius(4)
      .margin({ left: 2, right: 2 })
      .enabled(this.controlsEnabled)
      .backgroundColor(this.playbackSpeed === speed ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.playbackSpeed === speed ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .onClick(() => {
        if (this.photoImportLeaseActive || this.loading) {
          return;
        }
        this.onSpeedChange(speed);
      })
  }

  @Builder
  private RecordingRow(recording: MaterializedOriginalRecording, index: number) {
    Row() {
      Button(this.isPlaying(recording.id) ? 'Ⅱ' : '▶')
        .width(40).height(40).fontSize(16).borderRadius(4)
        .backgroundColor(this.isSelected(recording.id) ? this.resolveTokens().accent :
          this.resolveTokens().control)
        .fontColor(this.isSelected(recording.id) ? this.resolveTokens().onAccent :
          this.resolveTokens().textPrimary)
        .enabled(this.controlsEnabled &&
          recording.assetState === OriginalRecordingAssetState.READY)
        .opacity(this.controlsEnabled &&
          recording.assetState === OriginalRecordingAssetState.READY ? 1 : 0.4)
        .accessibilityText(this.isPlaying(recording.id) ? $r('app.string.pause_recording') :
          $r('app.string.play_recording'))
        .onClick(() => {
          if (this.photoImportLeaseActive || this.loading) {
            return;
          }
          this.onToggle(recording.id);
        })
      Column() {
        Text($r('app.string.recording_user_facing_name', index + 1))
          .fontSize(14)
          .fontWeight(this.isSelected(recording.id) ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.resolveTokens().textPrimary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.recordingSubtitle(recording))
          .fontSize(11)
          .fontColor(recording.assetState === OriginalRecordingAssetState.FAILED ?
            this.resolveTokens().danger : this.resolveTokens().textSecondary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
      Button($r('app.string.delete'))
        .height(32).fontSize(12).borderRadius(4)
        .backgroundColor(Color.Transparent)
        .fontColor(this.resolveTokens().danger)
        .accessibilityText($r('app.string.delete_recording'))
        .enabled(this.controlsEnabled)
        .onClick(() => {
          if (this.photoImportLeaseActive || this.loading) {
            return;
          }
          this.onDelete(recording.id);
        })
    }
    .width('100%').height(58).padding({ left: 8, right: 12 })
    .backgroundColor(this.isSelected(recording.id) ? this.resolveTokens().control : Color.Transparent)
  }

  @Builder
  private PendingDeleteRow(recording: MaterializedOriginalRecording) {
    Row() {
      Text($r('app.string.recording_deleted'))
        .fontSize(14)
        .fontColor(this.resolveTokens().textSecondary)
        .layoutWeight(1)
      Button($r('app.string.undo'))
        .height(32).fontSize(12).borderRadius(4)
        .backgroundColor(Color.Transparent)
        .fontColor(this.resolveTokens().accent)
        .enabled(this.controlsEnabled)
        .onClick(() => {
          if (this.photoImportLeaseActive || this.loading) {
            return;
          }
          this.onUndoDelete(recording.id);
        })
    }
    .width('100%').height(58).padding({ left: 12, right: 12 })
  }

  private isPendingDelete(recordingId: string): boolean {
    return this.pendingDeleteIds.indexOf(recordingId) >= 0;
  }

  private get controlsEnabled(): boolean {
    return !this.photoImportLeaseActive && !this.loading;
  }

  private isSelected(recordingId: string): boolean {
    return this.snapshot.recordingId === recordingId;
  }

  private isPlaying(recordingId: string): boolean {
    return this.isSelected(recordingId) &&
      this.snapshot.state === OriginalRecordingPlaybackState.PLAYING;
  }

  private canSeek(): boolean {
    return this.cumulativeDurationMs > 0 &&
      (this.snapshot.state === OriginalRecordingPlaybackState.READY ||
        this.snapshot.state === OriginalRecordingPlaybackState.PLAYING ||
        this.snapshot.state === OriginalRecordingPlaybackState.PAUSED ||
        this.snapshot.state === OriginalRecordingPlaybackState.COMPLETED);
  }

  private assetStatus(recording: MaterializedOriginalRecording): ResourceStr {
    if (this.isSelected(recording.id) &&
      this.snapshot.state === OriginalRecordingPlaybackState.FAILED) {
      return $r('app.string.recording_audio_failed');
    }
    if (recording.assetState === OriginalRecordingAssetState.READY) {
      return recording.assetFileName;
    }
    if (recording.assetState === OriginalRecordingAssetState.PENDING) {
      return $r('app.string.recording_waiting_for_audio');
    }
    if (recording.assetState === OriginalRecordingAssetState.MISSING) {
      return $r('app.string.recording_audio_missing');
    }
    return $r('app.string.recording_audio_failed');
  }

  private recordingSubtitle(recording: MaterializedOriginalRecording): ResourceStr {
    if (recording.assetState !== OriginalRecordingAssetState.READY) {
      return this.assetStatus(recording);
    }
    try {
      const presentation: OriginalRecordingPresentation =
        buildOriginalRecordingPresentation(recording);
      const date: Date = new Date(presentation.startTimeMs);
      const dateText: string = new Intl.DateTimeFormat(undefined,
        { dateStyle: 'medium' }).format(date);
      const timeText: string = new Intl.DateTimeFormat(undefined,
        { timeStyle: 'short' }).format(date);
      return $r('app.string.recording_subtitle', presentation.duration, dateText, timeText);
    } catch (_error) {
      return recording.assetFileName;
    }
  }
}

export function formatRecordingTime(milliseconds: number): string {
  if (!Number.isFinite(milliseconds) || milliseconds <= 0) {
    return '0:00';
  }
  const totalSeconds: number = Math.floor(milliseconds / 1000);
  const hours: number = Math.floor(totalSeconds / 3600);
  const minutes: number = Math.floor(totalSeconds / 60);
  const seconds: number = totalSeconds % 60;
  if (hours > 0) {
    const remainingMinutes: number = minutes % 60;
    return `${hours}:${remainingMinutes < 10 ? '0' : ''}${remainingMinutes}:` +
      `${seconds < 10 ? '0' : ''}${seconds}`;
  }
  return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
}

export function shouldShowRecordingTimeline(recordingId: string | null): boolean {
  return recordingId !== null;
}
