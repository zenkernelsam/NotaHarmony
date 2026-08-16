// T-025 笔记编辑器页面（EditorToolbar + NoteCanvasView + PageManagerBar 集成）
// T-036：标题行内编辑 + 持久化
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { audio } from '@kit.AudioKit';
import { NoteBackgroundSettings, NoteMeta, PageInfo } from '../../core/model/NoteTypes';
import {
  commitOriginalNoteTitleDraft, isOriginalNoteTitleWireValue,
  truncateOriginalNoteTitleDraft,
} from '../../core/model/OriginalNoteTitlePolicy';
import { originalDefaultTemplateFromSettings } from
  '../../core/model/OriginalDefaultTemplate';
import { BrushStyle, brushStyleToInkStyle } from '../../core/model/BrushTypes';
import { InkStyle } from '../../core/model/StrokeTypes';
import {
  cloneNoteBackgroundSettings, clonePageInfo, originalDefaultNoteBackgroundSettings,
  sameNoteBackgroundSettings, samePageBackground,
} from '../../core/model/PageBackgroundModel';
import { HistoryMetadata } from '../../core/model/OpTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { ToolRepositoryImpl } from '../../data/ToolRepositoryImpl';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import { AssetAvailabilityChange, assetAvailabilityHub } from '../../data/AssetAvailabilityHub';
import { MaterializedOriginalRecording, OriginalRecordingStore } from '../../data/OriginalRecordingStore';
import { OperationIdentity } from '../../data/OperationIdentity';
import {
  OriginalRecordingPlaybackController, OriginalRecordingPlaybackSnapshot,
  OriginalRecordingPlaybackSpeed, OriginalRecordingPlaybackState,
} from '../../core/adaptation/OriginalRecordingPlaybackController';
import {
  buildOriginalRecordingTimeline, locateOriginalRecordingTimeline,
  nextTimelineRecordingId, OriginalRecordingTimeline, OriginalRecordingTimelineLocation,
  timelinePositionForRecording,
} from '../../core/adaptation/OriginalRecordingTimeline';
import {
  effectiveOriginalAudioSegments, OriginalAudioSegmentRange, originalAudioTimeAtPosition,
} from '../../core/adaptation/OriginalAudioLinkedInkPlayback';
import { OriginalRecordingDeleteController } from
  '../../core/adaptation/OriginalRecordingDeleteController';
import {
  OriginalRecordingAudioSource, OriginalRecordingCaptureController, OriginalRecordingCaptureResult,
  OriginalRecordingCaptureState,
} from
  '../../core/adaptation/OriginalRecordingCaptureController';
import {
  HarmonyOriginalRecordingCaptureClock, OriginalRecordingMicrophoneBackend,
} from '../../core/adaptation/OriginalRecordingMicrophoneBackend';
import { OriginalRecordingInternalAudioBackend } from
  '../../core/adaptation/OriginalRecordingInternalAudioBackend';
import { OriginalRecordingSourceBackend } from
  '../../core/adaptation/OriginalRecordingSourceBackend';
import {
  isOriginalRecordingCaptureActive, OriginalRecordingSessionController,
  OriginalRecordingSessionFailure, OriginalRecordingSessionSnapshot,
} from '../../core/adaptation/OriginalRecordingSessionController';
import {
  HarmonyOriginalRecordingAudioFocusGateway, HarmonyOriginalRecordingPermissionGateway,
} from '../../core/adaptation/OriginalRecordingHarmonyGateways';
import { persistCapturedOriginalRecording } from '../../data/OriginalRecordingPersistence';
import {
  AddPageAction, DeletePageAction, EditorHistoryBridge, NoteBackgroundAction, NoteTitleAction,
  PageContentSnapshot, UndoableAction, UndoableActionType,
} from '../../rendering/UndoRedoManager';
import { EditorViewModel } from './EditorViewModel';
import { EditorToolbar } from './EditorToolbar';
import { NoteCanvasView } from './NoteCanvasView';
import { PageManagerBar } from './PageManagerBar';
import { RecordingPanel } from './RecordingPanel';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct NotePage {
  private noteId: string = '';
  @State viewModel: EditorViewModel = new EditorViewModel();
  @State pages: PageInfo[] = [];
  @State noteBackground: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
  @State currentPageIndex: number = 0;
  @State undoSignal: number = 0;
  @State redoSignal: number = 0;
  @State mathInsertSignal: number = 0;
  @State selectionStyleSignal: number = 0;
  @State selectionInkStyle: InkStyle = InkStyle.FIXED_WIDTH;
  @State selectionColorSignal: number = 0;
  @State selectionInkColor: number = -16777216;
  @State selectionWidthSignal: number = 0;
  @State selectionInkWidth: number = 5;
  @State selectionWidthMinimum: number = 0.5;
  @State selectionWidthMaximum: number = 30;
  @State selectionVariableStyleEnabled: boolean = true;
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  @State pageOperationBusy: boolean = false;
  @State pageLoading: boolean = false;
  @State pageLoadFailed: boolean = false;
  @State noteTitle: string = '';          // T-036：标题
  @State editingTitle: boolean = false;   // T-036：标题编辑态
  @State titleDraft: string = '';
  @State recordings: MaterializedOriginalRecording[] = [];
  @State recordingsLoading: boolean = false;
  @State showRecordings: boolean = false;
  @State playbackSnapshot: OriginalRecordingPlaybackSnapshot = {
    state: OriginalRecordingPlaybackState.IDLE, recordingId: null,
    positionMs: 0, durationMs: 0, error: null,
  };
  @State playbackCumulativePositionMs: number = 0;
  @State playbackCumulativeDurationMs: number = 0;
  @State recordingPlaybackSpeed: OriginalRecordingPlaybackSpeed =
    OriginalRecordingPlaybackSpeed.SPEED_1_0;
  @State pendingRecordingDeleteIds: string[] = [];
  @State recordingSessionSnapshot: OriginalRecordingSessionSnapshot = {
    captureState: OriginalRecordingCaptureState.IDLE, elapsedMs: 0,
    preparing: false, saving: false,
    failure: OriginalRecordingSessionFailure.NONE, failureSequence: 0,
  };
  @State recordingPauseSupported: boolean = true;
  @State audioPlaybackTime: string | null = null;
  @State audioPlaybackSegments: OriginalAudioSegmentRange[] = [];
  private noteRepo: NoteRepositoryImpl | null = null;
  private titleSaveQueue: Promise<void> = Promise.resolve();
  private titleSaveGeneration: number = 0;
  private pageRepo: PageRepositoryImpl | null = null;
  private editorSettingsStore: EditorSettingsStore | null = null;
  private persistence: StrokePersistence = new StrokePersistence();
  private historyBridge: EditorHistoryBridge | null = null;
  private pageLoadInFlight: boolean = false;
  private recordingStore: OriginalRecordingStore | null = null;
  private recordingController: OriginalRecordingPlaybackController =
    new OriginalRecordingPlaybackController();
  private recordingDeleteController: OriginalRecordingDeleteController =
    new OriginalRecordingDeleteController(async (recordingIds: string[]): Promise<void> => {
      await this.commitRecordingDeletes(recordingIds);
    });
  private recordingSessionController: OriginalRecordingSessionController | null = null;
  private recordingSessionTimer: number = -1;
  private recordingFailureSequence: number = 0;
  private assetAvailabilitySubscription: number = -1;
  private recordingLoadGeneration: number = 0;
  private recordingTimeline: OriginalRecordingTimeline = {
    entries: [], boundaryTimesMs: [], totalDurationMs: 0,
  };
  private completionAdvanceInFlight: boolean = false;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params['noteId'] !== undefined) {
      this.noteId = params['noteId'];
    }
    if (this.recordingSessionController === null) {
      const context = getContext(this) as common.UIAbilityContext;
      const sourceBackend: OriginalRecordingSourceBackend = new OriginalRecordingSourceBackend(
        new OriginalRecordingMicrophoneBackend(context.tempDir),
        new OriginalRecordingInternalAudioBackend(context.tempDir));
      const capture = new OriginalRecordingCaptureController(sourceBackend,
        new HarmonyOriginalRecordingCaptureClock(), sourceBackend);
      this.recordingSessionController = new OriginalRecordingSessionController(
        capture, new HarmonyOriginalRecordingPermissionGateway(context),
        new HarmonyOriginalRecordingAudioFocusGateway(),
        async (result: OriginalRecordingCaptureResult): Promise<void> => {
          await this.persistCapturedRecording(result);
        },
        async (): Promise<void> => {
          await this.recordingController.unload();
        });
      this.recordingSessionController.setListener((snapshot: OriginalRecordingSessionSnapshot): void => {
        this.onRecordingSessionSnapshot(snapshot);
      });
    }
    this.recordingController.setListener((snapshot: OriginalRecordingPlaybackSnapshot): void => {
      this.onRecordingPlaybackSnapshot(snapshot);
    });
    this.recordingDeleteController.setListener((pendingIds: string[]): void => {
      this.pendingRecordingDeleteIds = pendingIds;
      this.rebuildRecordingTimeline();
    });
    this.recordingDeleteController.setFailureListener((error: Object): void => {
      console.error(`Recording delete failed: ${JSON.stringify(error)}`);
      try {
        promptAction.showToast({ message: $r('app.string.recording_delete_failed'), duration: 2500 });
      } catch (_toastError) {
      }
    });
    if (this.assetAvailabilitySubscription < 0) {
      this.assetAvailabilitySubscription = assetAvailabilityHub.subscribe(
        (change: AssetAvailabilityChange): void => this.onRecordingAssetAvailabilityChanged(change));
    }
    this.loadPages();
  }

  // T-040 修复：路由返回时 TextInput 的 onBlur 不保证触发，必须在页面销毁时兜底保存标题
  aboutToDisappear(): void {
    this.recordingLoadGeneration++;
    if (this.editingTitle) {
      this.saveTitle();
    }
    if (this.assetAvailabilitySubscription >= 0) {
      assetAvailabilityHub.unsubscribe(this.assetAvailabilitySubscription);
      this.assetAvailabilitySubscription = -1;
    }
    this.recordingController.release().catch((error: Object) => {
      console.warn(`Recording player release failed: ${JSON.stringify(error)}`);
    });
    this.recordingDeleteController.flush().catch((error: Object) => {
      console.warn(`Recording delete flush failed: ${JSON.stringify(error)}`);
    });
    this.finishRecordingSession();
  }

  onBackPress(): boolean {
    this.leaveEditor();
    return true;
  }

  private async leaveEditor(): Promise<void> {
    if (this.editingTitle) {
      await this.saveTitle();
    } else {
      // onSubmit/onBlur may already have hidden the editor while their durable
      // SET_METADATA transaction is still running.  Navigation must wait for it.
      await this.titleSaveQueue;
    }
    if (this.historyBridge !== null && !await this.historyBridge.flushCurrentPage()) {
      return;
    }
    await this.viewModel.flushToolState();
    await this.recordingDeleteController.flush();
    await this.finishRecordingSession();
    await this.recordingController.release();
    router.back();
  }

  private async loadPages(): Promise<void> {
    if (this.pageLoadInFlight) {
      return;
    }
    this.pageLoadInFlight = true;
    this.pageLoading = true;
    this.pageLoadFailed = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.pageRepo = new PageRepositoryImpl(db);
      this.persistence.initialize(db);
      this.recordingStore = new OriginalRecordingStore(db);
      this.viewModel.onPersistenceError = (message: string): void => {
        hilog.error(0x0001, 'NotePage', '%{public}s', message);
        try {
          promptAction.showToast({ message: 'Tool settings could not be saved', duration: 2500 });
        } catch (toastError) {
          console.error(`Tool settings toast failed: ${JSON.stringify(toastError)}`);
        }
      };
      const editorSettingsStore: EditorSettingsStore = new EditorSettingsStore(context);
      this.editorSettingsStore = editorSettingsStore;
      await this.viewModel.initialize(
        new ToolRepositoryImpl(db), 'primary-editor', editorSettingsStore);
      // T-036：加载标题
      this.noteRepo = new NoteRepositoryImpl(db);
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      if (note === null) {
        throw new Error('note does not exist');
      }
      this.noteTitle = note.title;
      const loaded: PageInfo[] = await this.pageRepo.getPages(this.noteId);
      if (loaded.length === 0) {
        // Legacy/corrupt zero-page recovery only. Normal original blank-note creation has
        // already committed two inherited Letter pages before this editor can open it.
        const fallback: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
        const defaultPage: PageInfo = {
          pageId: this.generateId(),
          pageIndex: 0,
          size: fallback.size,
          template: fallback.template,
          orientation: fallback.orientation,
          widthMm: fallback.widthMm,
          heightMm: fallback.heightMm,
        };
        const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, defaultPage);
        this.pages = [assignedPage];
      } else {
        this.pages = loaded;
      }
      this.noteBackground = await this.pageRepo.getNoteBackground(this.noteId);
      this.currentPageIndex = 0;
      this.pageLoadFailed = false;
      await this.loadRecordings();
    } catch (e) {
      this.pages = [];
      this.noteBackground = originalDefaultNoteBackgroundSettings();
      this.currentPageIndex = 0;
      this.historyBridge = null;
      this.pageRepo = null;
      this.noteRepo = null;
      this.recordingStore = null;
      this.recordings = [];
      this.rebuildRecordingTimeline();
      this.pageLoadFailed = true;
      console.error(`NotePage loadPages failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.note_open_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Note page load toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.pageLoading = false;
      this.pageLoadInFlight = false;
    }
  }

  // Original title commits are serialized so onSubmit + onBlur + route teardown cannot
  // race two SET_METADATA operations or let navigation overtake an earlier save.
  private saveTitle(): Promise<void> {
    this.editingTitle = false;
    const requested: string = commitOriginalNoteTitleDraft(this.titleDraft);
    const generation: number = ++this.titleSaveGeneration;
    const queued: Promise<void> = this.titleSaveQueue.then(
      async (): Promise<void> => this.commitTitle(requested, generation));
    // Keep the tail usable even if an unexpected exception escapes commitTitle.
    // Callers can await `queued`, while the internal chain remains available to a
    // later edit instead of being permanently poisoned by one transient failure.
    this.titleSaveQueue = queued.catch((_error: Object): void => {
    });
    return queued;
  }

  private async commitTitle(requested: string, generation: number): Promise<void> {
    const previousTitle: string = this.noteTitle;
    if (requested === previousTitle) {
      this.publishTitleDraft(requested, generation);
      return;
    }
    try {
      if (this.noteRepo === null) {
        throw new Error('note repository is unavailable');
      }
      if (this.pages.length === 0 || this.currentPageIndex < 0 ||
        this.currentPageIndex >= this.pages.length) {
        throw new Error('note title requires a live selected page');
      }
      const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
      const action: NoteTitleAction = {
        type: UndoableActionType.NOTE_TITLE,
        noteId: this.noteId,
        pageId: selectedPageId,
        titleBefore: previousTitle,
        titleAfter: requested,
      };
      const bridge: EditorHistoryBridge | null = this.historyBridge;
      const history: HistoryMetadata | undefined = bridge === null
        ? undefined : bridge.preparePageAction(action);
      this.noteTitle = requested;
      this.publishTitleDraft(requested, generation);
      const materialized: string = await this.noteRepo.updateNoteTitle(
        this.noteId, requested, selectedPageId, history);
      action.titleAfter = materialized;
      this.noteTitle = materialized;
      this.publishTitleDraft(materialized, generation);
      if (bridge !== null) {
        try {
          bridge.pushPageAction(action, history);
        } catch (historyError) {
          // The SQLite transaction already committed both the original operation and
          // its durable history companion.  A runtime-stack race must not present the
          // old title again while reopening the note would materialize the new one.
          console.error(`saveTitle runtime history sync failed after durable commit: ${JSON.stringify(historyError)}`);
        }
      }
    } catch (e) {
      this.noteTitle = previousTitle;
      this.publishTitleDraft(previousTitle, generation);
      console.error(`saveTitle failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.note_save_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Title save failure toast failed: ${JSON.stringify(toastError)}`);
      }
    }
  }

  private publishTitleDraft(value: string, generation: number): void {
    // A completed older save must not overwrite a newer queued draft or text the
    // user has already started editing while the database operation was in flight.
    if (generation === this.titleSaveGeneration && !this.editingTitle) {
      this.titleDraft = value;
    }
  }

  private async loadRecordings(): Promise<void> {
    if (this.recordingStore === null || this.noteId.length === 0) {
      return;
    }
    const generation: number = ++this.recordingLoadGeneration;
    this.recordingsLoading = true;
    try {
      const recordings: MaterializedOriginalRecording[] =
        await this.recordingStore.listVisible(this.noteId);
      if (generation === this.recordingLoadGeneration) {
        this.recordings = recordings;
        this.rebuildRecordingTimeline();
      }
    } catch (error) {
      if (generation !== this.recordingLoadGeneration) {
        return;
      }
      this.recordings = [];
      this.rebuildRecordingTimeline();
      console.error(`Recording list load failed: ${JSON.stringify(error)}`);
      try {
        promptAction.showToast({ message: $r('app.string.recordings_load_failed'), duration: 2500 });
      } catch (_toastError) {
      }
    } finally {
      if (generation === this.recordingLoadGeneration) {
        this.recordingsLoading = false;
      }
    }
  }

  private async persistCapturedRecording(capture: OriginalRecordingCaptureResult): Promise<void> {
    await persistCapturedOriginalRecording(DatabaseManager.getInstance(), this.noteId, capture);
    await this.loadRecordings();
  }

  private onRecordingSessionSnapshot(snapshot: OriginalRecordingSessionSnapshot): void {
    this.recordingSessionSnapshot = snapshot;
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    this.recordingPauseSupported = session === null ? true : session.canPause();
    if (snapshot.failureSequence !== this.recordingFailureSequence) {
      this.recordingFailureSequence = snapshot.failureSequence;
      this.showRecordingFailure(snapshot.failure);
    }
    if (snapshot.preparing || snapshot.saving ||
      isOriginalRecordingCaptureActive(snapshot.captureState)) {
      this.scheduleRecordingSessionRefresh();
    } else {
      this.cancelRecordingSessionRefresh();
    }
  }

  private scheduleRecordingSessionRefresh(): void {
    if (this.recordingSessionTimer >= 0) {
      return;
    }
    this.recordingSessionTimer = setTimeout((): void => {
      this.recordingSessionTimer = -1;
      const session: OriginalRecordingSessionController | null = this.recordingSessionController;
      if (session !== null) {
        this.onRecordingSessionSnapshot(session.getSnapshot());
      }
    }, 250);
  }

  private cancelRecordingSessionRefresh(): void {
    if (this.recordingSessionTimer >= 0) {
      clearTimeout(this.recordingSessionTimer);
      this.recordingSessionTimer = -1;
    }
  }

  private showRecordingFailure(failure: OriginalRecordingSessionFailure): void {
    if (failure === OriginalRecordingSessionFailure.NONE) {
      return;
    }
    if (failure === OriginalRecordingSessionFailure.PERMISSION_DENIED) {
      promptAction.showDialog({
        title: $r('app.string.microphone_permission_title'),
        message: $r('app.string.microphone_permission_message'),
        buttons: [{ text: $r('app.string.dismiss'), color: this.resolveTokens().accent }],
      }).catch((_error: Object): void => {});
      return;
    }
    const message: ResourceStr = failure === OriginalRecordingSessionFailure.SAVE_FAILED ?
      $r('app.string.recording_save_failed') : $r('app.string.recording_start_failed');
    try {
      promptAction.showToast({ message: message, duration: 2500 });
    } catch (_toastError) {
    }
  }

  private async startRecording(): Promise<void> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session === null) {
      return;
    }
    let musicActive: boolean = false;
    try {
      musicActive = audio.getAudioManager().getStreamManager().isStreamActive(
        audio.StreamUsage.STREAM_USAGE_MUSIC);
    } catch (_error) {
    }
    if (!musicActive) {
      await session.start(OriginalRecordingAudioSource.MICROPHONE);
      return;
    }
    try {
      const response: promptAction.ShowDialogSuccessResponse = await promptAction.showDialog({
        title: $r('app.string.select_audio_source'),
        buttons: [
          { text: $r('app.string.audio_source_microphone'), color: this.resolveTokens().textPrimary },
          { text: $r('app.string.audio_source_internal'), color: this.resolveTokens().textPrimary },
        ],
      });
      if (response.index === 0) {
        await session.start(OriginalRecordingAudioSource.MICROPHONE);
      } else if (response.index === 1) {
        await session.start(OriginalRecordingAudioSource.DEVICE_ONLY);
      }
    } catch (_error) {
    }
  }

  private async pauseRecording(): Promise<void> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.pause();
    }
  }

  private async resumeRecording(): Promise<void> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.resume();
    }
  }

  private async stopRecording(): Promise<void> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.stop();
    }
  }

  private closeRecordings(): void {
    this.showRecordings = false;
  }

  private async finishRecordingSession(): Promise<boolean> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session === null) {
      return true;
    }
    this.recordingSessionController = null;
    this.cancelRecordingSessionRefresh();
    try {
      return await session.finishAndRelease();
    } catch (error) {
      console.warn(`Recording session release failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private async toggleRecording(recordingId: string): Promise<void> {
    const selected: MaterializedOriginalRecording | null = this.findRecording(recordingId);
    if (selected === null) {
      return;
    }
    if (this.playbackSnapshot.recordingId !== recordingId) {
      await this.recordingController.load(selected, true);
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.PLAYING) {
      await this.recordingController.pause();
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.LOADING) {
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.FAILED) {
      await this.recordingController.load(selected, true);
      return;
    }
    await this.recordingController.play();
  }

  private findRecording(recordingId: string): MaterializedOriginalRecording | null {
    for (const recording of this.recordings) {
      if (recording.id === recordingId) {
        return recording;
      }
    }
    return null;
  }

  private visiblePlaybackRecordings(): MaterializedOriginalRecording[] {
    return this.recordings.filter((recording: MaterializedOriginalRecording): boolean =>
      this.pendingRecordingDeleteIds.indexOf(recording.id) < 0);
  }

  private rebuildRecordingTimeline(): void {
    this.recordingTimeline = buildOriginalRecordingTimeline(this.visiblePlaybackRecordings());
    this.playbackCumulativeDurationMs = this.recordingTimeline.totalDurationMs;
    this.rebuildAudioPlaybackSegments();
    this.updateCumulativePlaybackPosition(this.playbackSnapshot);
    this.updateAudioPlaybackTime(this.playbackSnapshot);
  }

  private onRecordingPlaybackSnapshot(snapshot: OriginalRecordingPlaybackSnapshot): void {
    this.playbackSnapshot = snapshot;
    this.updateCumulativePlaybackPosition(snapshot);
    this.updateAudioPlaybackTime(snapshot);
    if (snapshot.state !== OriginalRecordingPlaybackState.COMPLETED) {
      this.completionAdvanceInFlight = false;
      return;
    }
    if (!this.completionAdvanceInFlight && snapshot.recordingId !== null) {
      this.completionAdvanceInFlight = true;
      this.advanceAfterRecordingCompletion(snapshot.recordingId);
    }
  }

  private updateCumulativePlaybackPosition(snapshot: OriginalRecordingPlaybackSnapshot): void {
    if (snapshot.recordingId === null) {
      this.playbackCumulativePositionMs = 0;
      return;
    }
    const localPosition: number = snapshot.state === OriginalRecordingPlaybackState.COMPLETED ?
      Number.MAX_SAFE_INTEGER : snapshot.positionMs;
    this.playbackCumulativePositionMs = timelinePositionForRecording(
      this.recordingTimeline, snapshot.recordingId, localPosition);
  }

  private rebuildAudioPlaybackSegments(): void {
    const result: OriginalAudioSegmentRange[] = [];
    for (const recording of this.visiblePlaybackRecordings()) {
      const sourceSegments: OriginalAudioSegmentRange[] = [];
      for (const segment of recording.segments) {
        sourceSegments.push({ startTime: segment.startTime, endTime: segment.endTime });
      }
      const ranges: OriginalAudioSegmentRange[] = effectiveOriginalAudioSegments(
        sourceSegments, recording.startTime, recording.endTime);
      result.push(...ranges);
    }
    this.audioPlaybackSegments = result;
  }

  private updateAudioPlaybackTime(snapshot: OriginalRecordingPlaybackSnapshot): void {
    if (snapshot.recordingId === null || snapshot.state === OriginalRecordingPlaybackState.IDLE ||
      snapshot.state === OriginalRecordingPlaybackState.FAILED ||
      snapshot.state === OriginalRecordingPlaybackState.RELEASED) {
      this.audioPlaybackTime = null;
      return;
    }
    const recording: MaterializedOriginalRecording | null = this.findRecording(snapshot.recordingId);
    if (recording === null) {
      this.audioPlaybackTime = null;
      return;
    }
    let range: OriginalAudioSegmentRange;
    if (recording.segments.length === 0) {
      range = { startTime: recording.startTime, endTime: recording.endTime };
    } else {
      range = { startTime: recording.segments[0].startTime,
        endTime: recording.segments[0].endTime };
    }
    const localPosition: number = snapshot.state === OriginalRecordingPlaybackState.COMPLETED ?
      Number.MAX_SAFE_INTEGER : snapshot.positionMs;
    try {
      this.audioPlaybackTime = originalAudioTimeAtPosition(
        range.startTime, range.endTime, localPosition);
    } catch (_error) {
      this.audioPlaybackTime = null;
    }
  }

  private async advanceAfterRecordingCompletion(recordingId: string): Promise<void> {
    const nextId: string | null = nextTimelineRecordingId(this.recordingTimeline, recordingId);
    if (nextId === null) {
      return;
    }
    const next: MaterializedOriginalRecording | null = this.findRecording(nextId);
    if (next !== null) {
      await this.recordingController.load(next, true);
    }
  }

  private async seekRecordingTimeline(positionMs: number): Promise<void> {
    const location: OriginalRecordingTimelineLocation | null =
      locateOriginalRecordingTimeline(this.recordingTimeline, positionMs);
    if (location === null) {
      return;
    }
    if (this.playbackSnapshot.recordingId === location.recordingId) {
      this.recordingController.seek(location.localPositionMs);
      return;
    }
    const recording: MaterializedOriginalRecording | null = this.findRecording(location.recordingId);
    if (recording === null) {
      return;
    }
    const resumePlayback: boolean =
      this.playbackSnapshot.state === OriginalRecordingPlaybackState.PLAYING;
    await this.recordingController.load(recording, resumePlayback, location.localPositionMs);
  }

  private changeRecordingPlaybackSpeed(speed: OriginalRecordingPlaybackSpeed): void {
    if (this.recordingController.setSpeed(speed)) {
      this.recordingPlaybackSpeed = speed;
    }
  }

  private async requestRecordingDelete(recordingId: string): Promise<void> {
    const recording: MaterializedOriginalRecording | null = this.findRecording(recordingId);
    if (recording === null || !this.recordingDeleteController.request(recordingId)) {
      return;
    }
    if (this.playbackSnapshot.recordingId === recordingId) {
      await this.recordingController.unload();
    }
  }

  private undoRecordingDelete(recordingId: string): void {
    this.recordingDeleteController.undo(recordingId);
  }

  private async commitRecordingDeletes(recordingIds: string[]): Promise<void> {
    if (this.recordingStore === null) {
      throw new Error('recording store is unavailable');
    }
    const targets: MaterializedOriginalRecording[] = [];
    for (const recordingId of recordingIds) {
      const recording: MaterializedOriginalRecording | null = this.findRecording(recordingId);
      if (recording === null) {
        throw new Error('pending recording delete target disappeared');
      }
      targets.push(recording);
    }
    await this.recordingStore.deleteVisible(this.noteId, targets.map(
      (recording: MaterializedOriginalRecording): OperationIdentity => ({
        timestamp: recording.timestamp, siteId: recording.siteId,
      })));
    await this.loadRecordings();
  }

  private onRecordingAssetAvailabilityChanged(change: AssetAvailabilityChange): void {
    if (change.noteIds.indexOf(this.noteId) >= 0) {
      this.loadRecordings();
    }
  }

  build() {
    Column() {
      // 顶部导航行（48vp）
      Row() {
        Button($r('app.string.back'))
          .height(36)
          .fontSize(14)
          .onClick(async () => {
            // T-040 修复：先等待标题保存完成再返回，避免与 LibraryPage onPageShow 刷新竞态
            await this.leaveEditor();
          })
        if (this.editingTitle) {
          // T-036：标题编辑态（TextInput，失焦/回车保存）
          TextInput({ text: this.titleDraft })
            .layoutWeight(1)
            .height(36)
            .fontSize(16)
            .margin({ left: 12 })
            .onChange((value: string) => {
              this.titleDraft = truncateOriginalNoteTitleDraft(value);
            })
            .onSubmit(() => {
              this.saveTitle();
            })
            .onBlur(() => {
              this.saveTitle();
            })
        } else {
          Text(this.noteTitle.length > 0 ? this.noteTitle : $r('app.string.untitled_note'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary)
            .margin({ left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .onClick(() => {
              if (this.pageLoadFailed || this.pageLoading) {
                return;
              }
              this.titleDraft = this.noteTitle;
              this.editingTitle = true;
            })
        }
        Button($r('app.string.recordings'))
          .height(36)
          .fontSize(13)
          .margin({ left: 8 })
          .enabled(!this.pageLoading && !this.pageLoadFailed)
          .onClick(() => {
            if (this.showRecordings) {
              this.closeRecordings();
            } else {
              this.showRecordings = true;
            }
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.resolveTokens().surface)

      // 工具栏
      if (this.pages.length > 0) {
        EditorToolbar({
          viewModel: this.viewModel,
          canUndo: this.canUndo,
          canRedo: this.canRedo,
          onUndo: () => {
            this.undoSignal++;
          },
          onRedo: () => {
            this.redoSignal++;
          },
          onInsertMath: () => {
            this.mathInsertSignal++;
          },
          onSelectionStyle: (style: BrushStyle) => {
            this.selectionInkStyle = brushStyleToInkStyle(style);
            this.selectionStyleSignal++;
          },
          selectionColor: this.selectionInkColor,
          selectionWidth: this.selectionInkWidth,
          selectionWidthMinimum: this.selectionWidthMinimum,
          selectionWidthMaximum: this.selectionWidthMaximum,
          selectionVariableStyleEnabled: this.selectionVariableStyleEnabled,
          onSelectionColor: (color: number) => {
            this.selectionInkColor = color;
            this.selectionColorSignal++;
          },
          onSelectionWidth: (width: number) => {
            this.selectionInkWidth = width;
            this.selectionWidthSignal++;
          },
        })
      }

      if (this.showRecordings && this.pages.length > 0) {
        RecordingPanel({
          recordings: this.recordings,
          loading: this.recordingsLoading,
          snapshot: this.playbackSnapshot,
          cumulativePositionMs: this.playbackCumulativePositionMs,
          cumulativeDurationMs: this.playbackCumulativeDurationMs,
          playbackSpeed: this.recordingPlaybackSpeed,
          pendingDeleteIds: this.pendingRecordingDeleteIds,
          captureSnapshot: this.recordingSessionSnapshot,
          capturePauseSupported: this.recordingPauseSupported,
          onRecord: () => {
            this.startRecording();
          },
          onPauseCapture: () => {
            this.pauseRecording();
          },
          onResumeCapture: () => {
            this.resumeRecording();
          },
          onStopCapture: () => {
            this.stopRecording();
          },
          onToggle: (recordingId: string) => {
            this.toggleRecording(recordingId);
          },
          onSeek: (positionMs: number) => {
            this.seekRecordingTimeline(positionMs);
          },
          onSpeedChange: (speed: OriginalRecordingPlaybackSpeed) => {
            this.changeRecordingPlaybackSpeed(speed);
          },
          onDelete: (recordingId: string) => {
            this.requestRecordingDelete(recordingId);
          },
          onUndoDelete: (recordingId: string) => {
            this.undoRecordingDelete(recordingId);
          },
          onClose: () => {
            this.closeRecordings();
          },
        })
      }

      // 画布（layoutWeight 撑满）
      if (this.pages.length > 0) {
        NoteCanvasView({
          viewModel: this.viewModel,
          noteId: this.noteId,
          currentPage: this.pages[this.currentPageIndex],
          undoSignal: this.undoSignal,
          redoSignal: this.redoSignal,
          mathInsertSignal: this.mathInsertSignal,
          selectionStyleSignal: this.selectionStyleSignal,
          selectionInkStyle: this.selectionInkStyle,
          selectionColorSignal: this.selectionColorSignal,
          selectionInkColor: this.selectionInkColor,
          selectionWidthSignal: this.selectionWidthSignal,
          selectionInkWidth: this.selectionInkWidth,
          playbackAudioTime: this.audioPlaybackTime,
          playbackAudioSegments: this.audioPlaybackSegments,
          readRecordingAudioTime: (): string | null => {
            const session: OriginalRecordingSessionController | null =
              this.recordingSessionController;
            return session === null ? null : session.getCurrentAudioTime();
          },
          onUndoRedoChanged: (u: boolean, r: boolean) => {
            hilog.info(0x0001, 'NotePage', 'undoRedoChanged u=%{public}s r=%{public}s',
              u.toString(), r.toString());
            this.canUndo = u;
            this.canRedo = r;
          },
          onRequestPage: (pageId: string) => {
            for (let i: number = 0; i < this.pages.length; i++) {
              if (this.pages[i].pageId === pageId) {
                this.currentPageIndex = i;
                return;
              }
            }
            hilog.error(0x0001, 'NotePage', 'history requested missing page %{public}s', pageId);
          },
          onHistoryBridgeReady: (bridge: EditorHistoryBridge) => {
            this.historyBridge = bridge;
          },
          onSelectionInkControlsChanged: (color: number, width: number,
            minimum: number, maximum: number, variableStyleEnabled: boolean) => {
            this.selectionInkColor = color;
            this.selectionInkWidth = width;
            this.selectionWidthMinimum = minimum;
            this.selectionWidthMaximum = maximum;
            this.selectionVariableStyleEnabled = variableStyleEnabled;
          },
          onApplyPageHistory: async (action: UndoableAction, isUndo: boolean,
            history: HistoryMetadata): Promise<boolean> => this.applyPageHistory(action, isUndo, history),
        })
          .layoutWeight(1)
      } else if (this.pageLoadFailed) {
        Column() {
          Text($r('app.string.note_open_failed'))
            .fontSize(16)
            .fontColor(this.resolveTokens().textSecondary)
            .textAlign(TextAlign.Center)
          Button($r('app.string.retry'))
            .height(36)
            .margin({ top: 12 })
            .onClick(() => {
              this.loadPages();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Text($r('app.string.loading_note'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }

      // 页面管理条（56vp 底部；异步加载完成前不能传入 undefined currentPage）
      if (this.pages.length > 0) {
        PageManagerBar({
          currentPageIndex: this.currentPageIndex,
          pageCount: this.pages.length,
          noteBackground: this.noteBackground,
          busy: this.pageOperationBusy,
          onPrev: () => {
            if (!this.pageLoading && !this.pageOperationBusy && this.currentPageIndex > 0) {
              this.currentPageIndex--;
            }
          },
          onNext: () => {
            if (!this.pageLoading && !this.pageOperationBusy &&
              this.currentPageIndex < this.pages.length - 1) {
              this.currentPageIndex++;
            }
          },
          onAdd: () => {
            this.runPageOperation(async (): Promise<void> => this.addPage());
          },
          onDelete: () => {
            this.runPageOperation(async (): Promise<void> => this.deleteCurrentPage());
          },
          onMovePrevious: () => {
            this.runPageOperation(async (): Promise<void> => this.moveCurrentPage(-1));
          },
          onMoveNext: () => {
            this.runPageOperation(async (): Promise<void> => this.moveCurrentPage(1));
          },
          onApplyNoteBackground: (settings: NoteBackgroundSettings) => {
            this.runPageOperation(
              async (): Promise<void> => this.applyNoteBackgroundSettings(settings));
          },
          onSetDefaultNoteBackground: (settings: NoteBackgroundSettings) => {
            this.runPageOperation(
              async (): Promise<void> => this.saveDefaultNoteBackground(settings));
          },
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }

  // Original 1.0.3 applies size/template/orientation through note-level SET_METADATA.
  private async applyNoteBackgroundSettings(settings: NoteBackgroundSettings): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    const before: NoteBackgroundSettings = cloneNoteBackgroundSettings(this.noteBackground);
    if (sameNoteBackgroundSettings(before, settings)) {
      return;
    }
    const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
    const action: NoteBackgroundAction = {
      type: UndoableActionType.NOTE_BACKGROUND,
      noteId: this.noteId,
      pageId: selectedPageId,
      selectedPageId: selectedPageId,
      backgroundBefore: before,
      backgroundAfter: cloneNoteBackgroundSettings(settings),
    };
    const history: HistoryMetadata | undefined = this.historyBridge === null
      ? undefined : this.historyBridge.preparePageAction(action);
    const materialized: NoteBackgroundSettings = await this.pageRepo.updateNoteBackground(
      this.noteId, settings, selectedPageId, history);
    action.backgroundAfter = cloneNoteBackgroundSettings(materialized);
    this.pages = await this.pageRepo.getPages(this.noteId);
    this.noteBackground = materialized;
    this.selectPageById(selectedPageId);
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction(action, history);
    }
  }

  private async saveDefaultNoteBackground(settings: NoteBackgroundSettings): Promise<void> {
    if (this.editorSettingsStore === null) {
      throw new Error('editor settings are unavailable');
    }
    await this.editorSettingsStore.saveSelectedDefaultTemplate(
      originalDefaultTemplateFromSettings(settings));
    try {
      promptAction.showToast({ message: $r('app.string.default_template_saved'), duration: 1800 });
    } catch (_toastError) {
    }
  }

  private async runPageOperation(operation: () => Promise<void>): Promise<void> {
    if (this.pageOperationBusy) {
      return;
    }
    this.pageOperationBusy = true;
    try {
      await operation();
    } catch (e) {
      hilog.error(0x0001, 'NotePage', 'page operation failed: %{public}s', JSON.stringify(e));
      try {
        promptAction.showToast({ message: $r('app.string.page_operation_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Page operation toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.pageOperationBusy = false;
    }
  }

  private async addPage(): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    const selectedBefore: string = this.pages[this.currentPageIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const page: PageInfo = {
      pageId: this.generateId(),
      pageIndex: this.pages.length,
      size: this.noteBackground.size,
      template: this.noteBackground.template,
      orientation: this.noteBackground.orientation,
      widthMm: this.noteBackground.widthMm,
      heightMm: this.noteBackground.heightMm,
      background: null,
    };
    const orderAfter: string[] = orderBefore.concat([page.pageId]);
    const action: AddPageAction = {
      type: UndoableActionType.ADD_PAGE,
      noteId: this.noteId,
      pageId: page.pageId,
      pageAfter: this.clonePage(page),
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
      pageStrokes: [],
      pageTextBlocks: [],
      pageShapes: [],
      pageImages: [],
      pageMathBlocks: [],
      pageElementOrder: [],
      selectedPageIdBefore: selectedBefore,
      selectedPageIdAfter: page.pageId,
    };
    const history: HistoryMetadata | undefined = this.historyBridge === null
      ? undefined : this.historyBridge.preparePageAction(action);
    const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, page, history);
    action.pageId = assignedPage.pageId;
    action.pageAfter = this.clonePage(assignedPage);
    action.pageOrderAfter = orderBefore.concat([assignedPage.pageId]);
    action.selectedPageIdAfter = assignedPage.pageId;
    const updated: PageInfo[] = this.pages.slice();
    updated.push(assignedPage);
    this.pages = updated;
    this.currentPageIndex = this.pages.length - 1;
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction(action, history);
    }
  }

  private async deleteCurrentPage(): Promise<void> {
    if (this.pageRepo === null || this.pages.length <= 1 || this.historyBridge === null) {
      return;
    }
    const deletedPage: PageInfo = this.clonePage(this.pages[this.currentPageIndex]);
    const pageId: string = deletedPage.pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const orderAfter: string[] = orderBefore.filter((id: string): boolean => id !== pageId);
    const selectedBefore: string = pageId;
    const selectedAfter: string = orderAfter[Math.min(this.currentPageIndex, orderAfter.length - 1)];
    if (!await this.historyBridge.flushCurrentPage()) {
      throw new Error('deleteCurrentPage could not flush the current page');
    }
    const snapshot: PageContentSnapshot = this.historyBridge.captureCurrentPage();
    const action: DeletePageAction = {
      type: UndoableActionType.DELETE_PAGE,
      noteId: this.noteId,
      pageId: pageId,
      pageBefore: deletedPage,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
      pageStrokes: snapshot.strokes,
      pageTextBlocks: snapshot.textBlocks,
      pageShapes: snapshot.shapes,
      pageImages: snapshot.images,
      pageMathBlocks: snapshot.mathBlocks,
      pageElementOrder: snapshot.elementOrder,
      selectedPageIdBefore: selectedBefore,
      selectedPageIdAfter: selectedAfter,
    };
    const history: HistoryMetadata = this.historyBridge.preparePageAction(action);
    this.historyBridge.preparePageRemoval(pageId);
    try {
      await this.pageRepo.deletePageWithCheckpoint(this.noteId, pageId, history);
    } catch (e) {
      this.historyBridge.cancelPageRemoval(pageId);
      throw new Error(`deleteCurrentPage failed: ${JSON.stringify(e)}`);
    }
    const updated: PageInfo[] = [];
    for (const p of this.pages) {
      if (p.pageId !== pageId) {
        updated.push(p);
      }
    }
    this.pages = updated;
    if (this.currentPageIndex >= this.pages.length) {
      this.currentPageIndex = this.pages.length - 1;
    }
    this.historyBridge.pushPageAction(action, history);
  }

  private async moveCurrentPage(delta: number): Promise<void> {
    if (this.pageRepo === null || this.historyBridge === null) {
      return;
    }
    const targetIndex: number = this.currentPageIndex + delta;
    if (targetIndex < 0 || targetIndex >= this.pages.length) {
      return;
    }
    const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const orderAfter: string[] = orderBefore.slice();
    const displaced: string = orderAfter[targetIndex];
    orderAfter[targetIndex] = selectedPageId;
    orderAfter[this.currentPageIndex] = displaced;
    const action: UndoableAction = {
      type: UndoableActionType.REORDER_PAGES,
      noteId: this.noteId,
      pageId: selectedPageId,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
    };
    const history: HistoryMetadata = this.historyBridge.preparePageAction(action);
    await this.pageRepo.reorderPages(this.noteId, orderAfter, selectedPageId, history);
    this.pages = this.orderPages(this.pages, orderAfter);
    this.currentPageIndex = targetIndex;
    this.historyBridge.pushPageAction(action, history);
  }

  private async applyPageHistory(action: UndoableAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    const pageRepository: PageRepositoryImpl | null = this.pageRepo;
    if (action.noteId !== this.noteId) {
      hilog.error(0x0001, 'NotePage',
        'page history note mismatch, actionNote=%{public}s currentNote=%{public}s', action.noteId, this.noteId);
      return false;
    }
    if (action.type === UndoableActionType.NOTE_TITLE && this.noteRepo === null) {
      return false;
    }
    if (action.type !== UndoableActionType.NOTE_TITLE && pageRepository === null) {
      return false;
    }
    if (!this.validatePageActionState(action, isUndo)) {
      hilog.error(0x0001, 'NotePage',
        'page history source state mismatch, type=%{public}d undo=%{public}s', action.type, isUndo.toString());
      return false;
    }
    try {
      if (action.type === UndoableActionType.NOTE_TITLE) {
        const repository: NoteRepositoryImpl | null = this.noteRepo;
        if (repository === null) {
          return false;
        }
        const title: string = isUndo ? action.titleBefore : action.titleAfter;
        const materialized: string = await repository.updateNoteTitle(
          this.noteId, title, action.pageId, history);
        this.noteTitle = materialized;
        this.titleDraft = materialized;
        return true;
      }
      if (pageRepository === null) {
        return false;
      }
      if (action.type === UndoableActionType.ADD_PAGE) {
        return await this.applyAddPageHistory(action, isUndo, history);
      }
      if (action.type === UndoableActionType.DELETE_PAGE) {
        return await this.applyDeletePageHistory(action, isUndo, history);
      }
      if (action.type === UndoableActionType.PAGE_SETTINGS) {
        const page: PageInfo = isUndo ? action.pageBefore : action.pageAfter;
        await pageRepository.updatePage(page, history);
        this.replacePage(page);
        this.selectPageById(page.pageId);
        return true;
      }
      if (action.type === UndoableActionType.NOTE_BACKGROUND) {
        const settings: NoteBackgroundSettings = isUndo
          ? action.backgroundBefore : action.backgroundAfter;
        const materialized: NoteBackgroundSettings = await pageRepository.updateNoteBackground(
          this.noteId, settings, action.selectedPageId, history);
        this.pages = await pageRepository.getPages(this.noteId);
        this.noteBackground = materialized;
        this.selectPageById(action.selectedPageId);
        return true;
      }
      if (action.type === UndoableActionType.REORDER_PAGES) {
        const order: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
        await pageRepository.reorderPages(this.noteId, order, action.pageId, history);
        this.pages = this.orderPages(this.pages, order);
        this.selectPageById(action.pageId);
        return true;
      }
    } catch (e) {
      if (this.historyBridge !== null) {
        this.historyBridge.cancelPageRemoval(action.pageId);
      }
      hilog.error(0x0001, 'NotePage', 'applyPageHistory failed: %{public}s', JSON.stringify(e));
    }
    return false;
  }

  private validatePageActionState(action: UndoableAction, isUndo: boolean): boolean {
    const currentOrder: string[] = this.pageIds(this.pages);
    if (!this.hasUniqueStrings(currentOrder)) {
      return false;
    }
    if (action.type === UndoableActionType.ADD_PAGE) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      const sourceSelection: string = isUndo ? action.selectedPageIdAfter : action.selectedPageIdBefore;
      const targetSelection: string = isUndo ? action.selectedPageIdBefore : action.selectedPageIdAfter;
      return action.pageId === action.pageAfter.pageId && this.sameStringArray(currentOrder, sourceOrder) &&
        this.isSinglePageTransition(sourceOrder, targetOrder, action.pageId, isUndo) &&
        this.countString(sourceOrder, sourceSelection) === 1 && this.countString(targetOrder, targetSelection) === 1;
    }
    if (action.type === UndoableActionType.DELETE_PAGE) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      const sourceSelection: string = isUndo ? action.selectedPageIdAfter : action.selectedPageIdBefore;
      const targetSelection: string = isUndo ? action.selectedPageIdBefore : action.selectedPageIdAfter;
      return action.pageId === action.pageBefore.pageId && this.sameStringArray(currentOrder, sourceOrder) &&
        this.isSinglePageTransition(sourceOrder, targetOrder, action.pageId, !isUndo) &&
        this.countString(sourceOrder, sourceSelection) === 1 && this.countString(targetOrder, targetSelection) === 1;
    }
    if (action.type === UndoableActionType.REORDER_PAGES) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      return this.sameStringArray(currentOrder, sourceOrder) && this.sameStringMembers(sourceOrder, targetOrder) &&
        this.countString(targetOrder, action.pageId) === 1;
    }
    if (action.type === UndoableActionType.PAGE_SETTINGS) {
      const sourcePage: PageInfo = isUndo ? action.pageAfter : action.pageBefore;
      const targetPage: PageInfo = isUndo ? action.pageBefore : action.pageAfter;
      if (sourcePage.pageId !== action.pageId || targetPage.pageId !== action.pageId) {
        return false;
      }
      let matched: number = 0;
      for (const page of this.pages) {
        if (page.pageId === action.pageId && this.samePageSettings(page, sourcePage)) {
          matched++;
        }
      }
      return matched === 1;
    }
    if (action.type === UndoableActionType.NOTE_BACKGROUND) {
      const source: NoteBackgroundSettings = isUndo
        ? action.backgroundAfter : action.backgroundBefore;
      return action.pageId === action.selectedPageId &&
        this.countString(currentOrder, action.selectedPageId) === 1 &&
        sameNoteBackgroundSettings(this.noteBackground, source);
    }
    if (action.type === UndoableActionType.NOTE_TITLE) {
      const source: string = isUndo ? action.titleAfter : action.titleBefore;
      return action.titleBefore !== action.titleAfter &&
        isOriginalNoteTitleWireValue(action.titleBefore) &&
        isOriginalNoteTitleWireValue(action.titleAfter) &&
        this.countString(currentOrder, action.pageId) === 1 && this.noteTitle === source;
    }
    return false;
  }

  private isSinglePageTransition(source: string[], target: string[], pageId: string,
    sourceContainsPage: boolean): boolean {
    if (!this.hasUniqueStrings(source) || !this.hasUniqueStrings(target)) {
      return false;
    }
    if (sourceContainsPage) {
      if (source.length !== target.length + 1 || this.countString(source, pageId) !== 1 ||
        this.countString(target, pageId) !== 0) {
        return false;
      }
    } else if (target.length !== source.length + 1 || this.countString(source, pageId) !== 0 ||
      this.countString(target, pageId) !== 1) {
      return false;
    }
    const withoutPage: string[] = [];
    const longer: string[] = sourceContainsPage ? source : target;
    for (const id of longer) {
      if (id !== pageId) {
        withoutPage.push(id);
      }
    }
    return this.sameStringArray(withoutPage, sourceContainsPage ? target : source);
  }

  private sameStringMembers(a: string[], b: string[]): boolean {
    if (a.length !== b.length || !this.hasUniqueStrings(a) || !this.hasUniqueStrings(b)) {
      return false;
    }
    for (const value of a) {
      if (this.countString(b, value) !== 1) {
        return false;
      }
    }
    return true;
  }

  private sameStringArray(a: string[], b: string[]): boolean {
    if (a.length !== b.length) {
      return false;
    }
    for (let i: number = 0; i < a.length; i++) {
      if (a[i] !== b[i]) {
        return false;
      }
    }
    return true;
  }

  private hasUniqueStrings(values: string[]): boolean {
    for (let i: number = 0; i < values.length; i++) {
      for (let j: number = i + 1; j < values.length; j++) {
        if (values[i] === values[j]) {
          return false;
        }
      }
    }
    return true;
  }

  private countString(values: string[], value: string): number {
    let count: number = 0;
    for (const candidate of values) {
      if (candidate === value) {
        count++;
      }
    }
    return count;
  }

  private async applyAddPageHistory(action: AddPageAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    // A user-created page is appended empty. Keeping this invariant makes ADD_PAGE history a
    // single page-mutation transaction; populated page restoration belongs to DELETE_PAGE checkpoints.
    if (action.pageStrokes.length !== 0 || action.pageTextBlocks.length !== 0 ||
      action.pageShapes.length !== 0 || action.pageImages.length !== 0 ||
      (action.pageMathBlocks ?? []).length !== 0 ||
      action.pageElementOrder.length !== 0 ||
      action.pageOrderAfter.length === 0 ||
      action.pageOrderAfter[action.pageOrderAfter.length - 1] !== action.pageId) {
      return false;
    }
    if (isUndo) {
      if (this.pages.length <= 1) {
        return false;
      }
      if (this.historyBridge !== null && this.pages[this.currentPageIndex].pageId === action.pageId) {
        this.historyBridge.preparePageRemoval(action.pageId);
      }
      await this.pageRepo.deletePage(this.noteId, action.pageId, history);
      this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
        action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, action.pageAfter, history);
    if (assignedPage.pageId !== action.pageId) {
      throw new Error('ADD_PAGE redo changed the original page identity');
    }
    const restored: PageInfo[] = this.pages.concat([this.clonePage(assignedPage)]);
    this.pages = this.orderPages(restored, action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  private async applyDeletePageHistory(action: DeletePageAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    if (isUndo) {
      await this.pageRepo.restoreDeletedPage(this.noteId, history.actionId, history);
      const restored: PageInfo[] = this.pages.concat([this.clonePage(action.pageBefore)]);
      this.pages = this.orderPages(restored, action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    if (this.pages.length <= 1) {
      return false;
    }
    if (this.historyBridge !== null && this.pages[this.currentPageIndex].pageId === action.pageId) {
      this.historyBridge.preparePageRemoval(action.pageId);
    }
    await this.pageRepo.deletePageWithCheckpoint(this.noteId, action.pageId, history);
    this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
      action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  private replacePage(page: PageInfo): void {
    const updated: PageInfo[] = this.pages.slice();
    for (let i: number = 0; i < updated.length; i++) {
      if (updated[i].pageId === page.pageId) {
        updated[i] = this.clonePage(page);
        this.pages = updated;
        return;
      }
    }
  }

  private orderPages(source: PageInfo[], order: string[]): PageInfo[] {
    const result: PageInfo[] = [];
    for (let index: number = 0; index < order.length; index++) {
      for (const page of source) {
        if (page.pageId === order[index]) {
          const ordered: PageInfo = this.clonePage(page);
          ordered.pageIndex = index;
          result.push(ordered);
          break;
        }
      }
    }
    return result;
  }

  private selectPageById(pageId: string): void {
    for (let i: number = 0; i < this.pages.length; i++) {
      if (this.pages[i].pageId === pageId) {
        this.currentPageIndex = i;
        return;
      }
    }
  }

  private pageIds(pages: PageInfo[]): string[] {
    const ids: string[] = [];
    for (const page of pages) {
      ids.push(page.pageId);
    }
    return ids;
  }

  private clonePage(page: PageInfo): PageInfo {
    return clonePageInfo(page);
  }

  private samePageSettings(a: PageInfo, b: PageInfo): boolean {
    return a.size === b.size && a.template === b.template && a.orientation === b.orientation &&
      a.widthMm === b.widthMm && a.heightMm === b.heightMm &&
      a.originalPageInAsset === b.originalPageInAsset &&
      samePageBackground(a.background, b.background) &&
      samePageBackground(a.noteBackgroundFallback, b.noteBackgroundFallback);
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
