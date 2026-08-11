import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../../data/OriginalRecordingStore';
import { compareUnsignedLongDecimal } from '../../data/UnsignedDecimal';

const MAX_SAFE_INTEGER_DECIMAL: string = '9007199254740991';

export interface OriginalRecordingTimelineEntry {
  recordingId: string;
  recordingIndex: number;
  startMs: number;
  durationMs: number;
  endMs: number;
}

export interface OriginalRecordingTimeline {
  entries: OriginalRecordingTimelineEntry[];
  boundaryTimesMs: number[];
  totalDurationMs: number;
}

export interface OriginalRecordingTimelineLocation {
  recordingId: string;
  recordingIndex: number;
  localPositionMs: number;
}

export function buildOriginalRecordingTimeline(
  recordings: MaterializedOriginalRecording[]): OriginalRecordingTimeline {
  const entries: OriginalRecordingTimelineEntry[] = [];
  let cumulative: number = 0;
  for (let index: number = 0; index < recordings.length; index++) {
    const recording: MaterializedOriginalRecording = recordings[index];
    if (recording.assetState !== OriginalRecordingAssetState.READY) {
      continue;
    }
    let duration: number = 0;
    try {
      duration = originalRecordingEffectiveDurationMs(recording);
    } catch (_error) {
      continue;
    }
    if (!Number.isSafeInteger(duration) || duration < 0 || cumulative > Number.MAX_SAFE_INTEGER - duration) {
      continue;
    }
    entries.push({ recordingId: recording.id, recordingIndex: index,
      startMs: cumulative, durationMs: duration, endMs: cumulative + duration });
    cumulative += duration;
  }
  const boundaries: number[] = [];
  for (let index: number = 0; index + 1 < entries.length; index++) {
    boundaries.push(entries[index].endMs);
  }
  return { entries: entries, boundaryTimesMs: boundaries, totalDurationMs: cumulative };
}

export function originalRecordingEffectiveDurationMs(recording: MaterializedOriginalRecording): number {
  let start: string = recording.startTime;
  let end: string = recording.endTime;
  if (recording.segments.length > 0) {
    start = recording.segments[0].startTime;
    end = recording.segments[0].endTime;
  }
  return subtractUnsignedDecimalToSafeNumber(end, start);
}

export function locateOriginalRecordingTimeline(timeline: OriginalRecordingTimeline,
  cumulativePositionMs: number): OriginalRecordingTimelineLocation | null {
  if (timeline.entries.length === 0) {
    return null;
  }
  const target: number = clampTimelinePosition(cumulativePositionMs, timeline.totalDurationMs);
  for (let index: number = timeline.entries.length - 1; index >= 0; index--) {
    const entry: OriginalRecordingTimelineEntry = timeline.entries[index];
    if (entry.startMs <= target) {
      return { recordingId: entry.recordingId, recordingIndex: entry.recordingIndex,
        localPositionMs: Math.min(target - entry.startMs, entry.durationMs) };
    }
  }
  const first: OriginalRecordingTimelineEntry = timeline.entries[0];
  return { recordingId: first.recordingId, recordingIndex: first.recordingIndex, localPositionMs: 0 };
}

export function timelinePositionForRecording(timeline: OriginalRecordingTimeline,
  recordingId: string, localPositionMs: number): number {
  for (const entry of timeline.entries) {
    if (entry.recordingId === recordingId) {
      const local: number = clampTimelinePosition(localPositionMs, entry.durationMs);
      return entry.startMs + local;
    }
  }
  return 0;
}

export function nextTimelineRecordingId(timeline: OriginalRecordingTimeline,
  recordingId: string): string | null {
  for (let index: number = 0; index + 1 < timeline.entries.length; index++) {
    if (timeline.entries[index].recordingId === recordingId) {
      return timeline.entries[index + 1].recordingId;
    }
  }
  return null;
}

function clampTimelinePosition(positionMs: number, durationMs: number): number {
  if (!Number.isFinite(positionMs) || positionMs <= 0 || durationMs <= 0) {
    return 0;
  }
  return Math.min(Math.round(positionMs), durationMs);
}

function subtractUnsignedDecimalToSafeNumber(left: string, right: string): number {
  if (compareUnsignedLongDecimal(left, right) < 0) {
    throw new Error('recording duration has negative bounds');
  }
  let borrow: number = 0;
  let result: string = '';
  let leftIndex: number = left.length - 1;
  let rightIndex: number = right.length - 1;
  while (leftIndex >= 0) {
    const leftDigit: number = left.charCodeAt(leftIndex) - 0x30 - borrow;
    const rightDigit: number = rightIndex >= 0 ? right.charCodeAt(rightIndex) - 0x30 : 0;
    if (leftDigit < rightDigit) {
      result = `${leftDigit + 10 - rightDigit}${result}`;
      borrow = 1;
    } else {
      result = `${leftDigit - rightDigit}${result}`;
      borrow = 0;
    }
    leftIndex--;
    rightIndex--;
  }
  let firstNonZero: number = 0;
  while (firstNonZero + 1 < result.length && result.charAt(firstNonZero) === '0') {
    firstNonZero++;
  }
  const canonical: string = result.substring(firstNonZero);
  if (canonical.length > MAX_SAFE_INTEGER_DECIMAL.length ||
    (canonical.length === MAX_SAFE_INTEGER_DECIMAL.length && canonical > MAX_SAFE_INTEGER_DECIMAL)) {
    throw new Error('recording duration exceeds the safe player range');
  }
  return Number(canonical);
}
