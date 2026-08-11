import { MaterializedOriginalRecording } from '../../data/OriginalRecordingStore';
import { originalRecordingEffectiveDurationMs } from './OriginalRecordingTimeline';

const MAX_SAFE_INTEGER_DECIMAL: string = '9007199254740991';

export interface OriginalRecordingPresentation {
  duration: string;
  startTimeMs: number;
}

export function buildOriginalRecordingPresentation(
  recording: MaterializedOriginalRecording): OriginalRecordingPresentation {
  const start: string = recording.segments.length > 0 ?
    recording.segments[0].startTime : recording.startTime;
  return {
    duration: formatOriginalRecordingDuration(originalRecordingEffectiveDurationMs(recording)),
    startTimeMs: parseOriginalRecordingDateMilliseconds(start),
  };
}

export function formatOriginalRecordingDuration(milliseconds: number): string {
  if (!Number.isSafeInteger(milliseconds) || milliseconds < 0) {
    throw new Error('recording presentation duration is invalid');
  }
  const totalSeconds: number = Math.floor(milliseconds / 1000);
  const hours: number = Math.floor(totalSeconds / 3600);
  const minutes: number = Math.floor(totalSeconds / 60);
  const seconds: number = totalSeconds % 60;
  if (hours > 0) {
    return `${hours}h ${minutes % 60}m ${seconds}s`;
  }
  if (minutes > 0) {
    return `${minutes}m ${seconds}s`;
  }
  return `${seconds}s`;
}

export function parseOriginalRecordingDateMilliseconds(value: string): number {
  if (!/^(0|[1-9][0-9]*)$/.test(value) ||
    value.length > MAX_SAFE_INTEGER_DECIMAL.length ||
    (value.length === MAX_SAFE_INTEGER_DECIMAL.length && value > MAX_SAFE_INTEGER_DECIMAL)) {
    throw new Error('recording presentation start time is outside the Date range');
  }
  const milliseconds: number = Number(value);
  if (!Number.isSafeInteger(milliseconds)) {
    throw new Error('recording presentation start time is invalid');
  }
  const date: Date = new Date(milliseconds);
  if (!Number.isFinite(date.getTime())) {
    throw new Error('recording presentation start time is outside the Date range');
  }
  return milliseconds;
}
