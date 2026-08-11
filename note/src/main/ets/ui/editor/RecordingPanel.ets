import {
  OriginalRecordingPlaybackSnapshot, OriginalRecordingPlaybackSpeed,
  OriginalRecordingPlaybackState,
} from '../../core/adaptation/OriginalRecordingPlaybackController';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../../data/OriginalRecordingStore';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';

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
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onToggle: (recordingId: string) => void = () => {};
  onSeek: (positionMs: number) => void = () => {};
  onSpeedChange: (speed: OriginalRecordingPlaybackSpeed) => void = () => {};
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
          .onClick(() => this.onClose())
      }
      .width('100%').height(40).padding({ left: 12, right: 8 })

      if (!this.loading && this.recordings.length === 0) {
        Text($r('app.string.no_recordings'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textSecondary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.recordings, (recording: MaterializedOriginalRecording) => {
            ListItem() {
              this.RecordingRow(recording)
            }
          }, (recording: MaterializedOriginalRecording): string => recording.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: this.resolveTokens().border, startMargin: 56 })
      }

      if (this.snapshot.recordingId !== null) {
        Column() {
          Slider({ value: this.cumulativePositionMs, min: 0,
            max: Math.max(1, this.cumulativeDurationMs), step: 1 })
            .width('100%')
            .enabled(this.canSeek())
            .opacity(this.canSeek() ? 1 : 0.45)
            .selectedColor(this.resolveTokens().accent)
            .onChange((value: number) => this.onSeek(value))
          Row() {
            Text(formatRecordingTime(this.cumulativePositionMs))
              .fontSize(11).fontColor(this.resolveTokens().textSecondary)
            Blank()
            this.SpeedButton('1x', OriginalRecordingPlaybackSpeed.SPEED_1_0)
            this.SpeedButton('1.5x', OriginalRecordingPlaybackSpeed.SPEED_1_5)
            this.SpeedButton('2x', OriginalRecordingPlaybackSpeed.SPEED_2_0)
            Blank()
            Text(formatRecordingTime(this.cumulativeDurationMs))
              .fontSize(11).fontColor(this.resolveTokens().textSecondary)
          }
          .width('100%')
        }
        .height(52).padding({ left: 12, right: 12 })
      }
    }
    .width('100%').height(220)
    .backgroundColor(this.resolveTokens().surface)
    .border({ width: { top: 1, bottom: 1 }, color: this.resolveTokens().border })
  }

  @Builder
  private SpeedButton(label: string, speed: OriginalRecordingPlaybackSpeed) {
    Button(label)
      .width(42).height(26).fontSize(11).borderRadius(4)
      .margin({ left: 2, right: 2 })
      .backgroundColor(this.playbackSpeed === speed ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.playbackSpeed === speed ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .onClick(() => this.onSpeedChange(speed))
  }

  @Builder
  private RecordingRow(recording: MaterializedOriginalRecording) {
    Row() {
      Button(this.isPlaying(recording.id) ? 'Ⅱ' : '▶')
        .width(40).height(40).fontSize(16).borderRadius(4)
        .backgroundColor(this.isSelected(recording.id) ? this.resolveTokens().accent :
          this.resolveTokens().control)
        .fontColor(this.isSelected(recording.id) ? this.resolveTokens().onAccent :
          this.resolveTokens().textPrimary)
        .enabled(recording.assetState === OriginalRecordingAssetState.READY)
        .opacity(recording.assetState === OriginalRecordingAssetState.READY ? 1 : 0.4)
        .accessibilityText(this.isPlaying(recording.id) ? $r('app.string.pause_recording') :
          $r('app.string.play_recording'))
        .onClick(() => this.onToggle(recording.id))
      Column() {
        Text(recording.name)
          .fontSize(14)
          .fontWeight(this.isSelected(recording.id) ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.resolveTokens().textPrimary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.assetStatus(recording))
          .fontSize(11)
          .fontColor(recording.assetState === OriginalRecordingAssetState.FAILED ?
            this.resolveTokens().danger : this.resolveTokens().textSecondary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
    }
    .width('100%').height(58).padding({ left: 8, right: 12 })
    .backgroundColor(this.isSelected(recording.id) ? this.resolveTokens().control : Color.Transparent)
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
