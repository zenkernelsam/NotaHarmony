import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import {
  DEFAULT_AUTO_DESELECT_ERASER, DEFAULT_HIDE_NAVIGATION_BAR, DEFAULT_HIDE_STATUS_BAR,
  DEFAULT_KEEP_DEVICE_AWAKE, DEFAULT_NOTE_VIEW_NIGHT_MODE, DEFAULT_PALM_DETECTION,
  DEFAULT_RULER_UNITS, DEFAULT_SHAPE_DETECTION_ENABLED, DEFAULT_STRAIGHT_LINES,
  DEFAULT_UNDO_REDO_TAPS,
  DEFAULT_INCLUDE_DATE_POSITION, DEFAULT_INCLUDE_TIME_POSITION,
  EditorSettingsStore, RULER_UNITS_IMPERIAL, RULER_UNITS_METRIC,
} from '../../data/EditorSettingsStore';
import {
  formatOriginalAutoNoteTitle, NOTE_TITLE_POSITION_NONE,
  NOTE_TITLE_POSITION_PREFIX, NOTE_TITLE_POSITION_SUFFIX,
} from '../../core/model/OriginalNoteTitlePolicy';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';
import {
  OriginalHandwritingLanguageOption,
  ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE,
  originalHandwritingLanguageDisplayName,
  originalHandwritingRecognitionLanguageOptions,
  resolveOriginalHandwritingLanguage,
} from '../../core/model/OriginalHandwritingLanguagePolicy';
import { readHarmonyOriginalHandwritingLocale } from '../../core/adaptation/OriginalHandwritingLocaleAdapter';
import { OriginalHandwritingLanguagePreferenceStore } from '../../data/OriginalHandwritingLanguagePreferenceStore';
import { preferences } from '@kit.ArkData';
import {
  ThemeStore, THEME_MODE_KEY, THEME_PREFERENCES_NAME, THEME_PREFERENCE_KEY,
  THEME_SYSTEM_DARK_KEY,
} from '../theme/ThemeStore';

enum SettingsLoadState {
  LOADING = 'loading',
  ERROR = 'error',
  READY = 'ready',
}

// 原版 wxm.c 社交行条目：feature_settings__* 图标 + cd_* 语义 + j1 URL。
interface SocialLinkSpec {
  glyph: string;
  label: Resource;
  url: string;
}

@Entry
@Component
struct SettingsPage {
  @State loadState: SettingsLoadState = SettingsLoadState.LOADING;
  @State shapeDetectionEnabled: boolean = DEFAULT_SHAPE_DETECTION_ENABLED;
  @State keepDeviceAwakeEnabled: boolean = DEFAULT_KEEP_DEVICE_AWAKE;
  @State hideStatusBarEnabled: boolean = DEFAULT_HIDE_STATUS_BAR;
  @State hideNavigationBarEnabled: boolean = DEFAULT_HIDE_NAVIGATION_BAR;
  @State noteViewNightModeEnabled: boolean = DEFAULT_NOTE_VIEW_NIGHT_MODE;
  @State autoDeselectEraserEnabled: boolean = DEFAULT_AUTO_DESELECT_ERASER;
  @State palmDetectionEnabled: boolean = DEFAULT_PALM_DETECTION;
  @State straightLinesEnabled: boolean = DEFAULT_STRAIGHT_LINES;
  @State undoRedoTapsEnabled: boolean = DEFAULT_UNDO_REDO_TAPS;
  @State rulerUnits: string = DEFAULT_RULER_UNITS;
  @State recognitionLanguageCode: string = ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE;
  // 原版 ncn.a/yob：note_title 子屏 —— defaultNoteTitle 草稿
  //（存储 null→''），includeDate/includeTime 三态位置。
  @State defaultNoteTitle: string = '';
  @State includeDatePosition: string = DEFAULT_INCLUDE_DATE_POSITION;
  @State includeTimePosition: string = DEFAULT_INCLUDE_TIME_POSITION;
  // 原版 a96：example 预览用 remember{System.currentTimeMillis()} —— 进屏时刻。
  @State noteTitleExampleTs: number = 0;
  @State saveBusy: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private store: EditorSettingsStore | null = null;
  private languageStore: OriginalHandwritingLanguagePreferenceStore | null = null;
  private initialized: boolean = false;
  private loadGeneration: number = 0;
  private lifecycleGeneration: number = 0;
  private pageDisposed: boolean = false;
  // 原版 wxm.c 社交行顺序：instagram → youtube → tiktok → threads → linkedin。
  private readonly socialLinks: SocialLinkSpec[] = [
    {
      glyph: 'instagram', label: $r('app.string.feature_settings__cd_instagram'),
      url: 'https://www.instagram.com/notabilityapp',
    },
    {
      glyph: 'youtube', label: $r('app.string.feature_settings__cd_youtube'),
      url: 'https://youtube.com/notability',
    },
    {
      glyph: 'tiktok', label: $r('app.string.feature_settings__cd_tiktok'),
      url: 'https://www.tiktok.com/@notabilityapp',
    },
    {
      glyph: 'threads', label: $r('app.string.feature_settings__cd_threads'),
      url: 'https://www.threads.com/@notabilityapp',
    },
    {
      glyph: 'linkedin', label: $r('app.string.feature_settings__cd_linkedin'),
      url: 'https://www.linkedin.com/company/ginger-labs',
    },
  ];
  // 原版 vmc 语言选择器：dc5 全部 23 项列表，点选写全局识别语言偏好。
  private languageDialog: CustomDialogController = new CustomDialogController({
    builder: HandwritingLanguageDialog({
      selected: this.recognitionLanguageCode,
      onPick: (localeCode: string): void => {
        this.setRecognitionLanguage(localeCode).catch((e: Error) => {
          console.error(`SettingsPage language pick failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });
  // 原版 n94：ruler_units 选择器，oof.N 顺序 Imperial→Metric。
  private rulerUnitsDialog: CustomDialogController = new CustomDialogController({
    builder: RulerUnitsDialog({
      selected: this.rulerUnits,
      onPick: (units: string): void => {
        this.setRulerUnits(units).catch((e: Error) => {
          console.error(`SettingsPage ruler-units pick failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });
  // 原版 ibb：include_date/include_time 行的 None/Prefix/Suffix 下拉选择器。
  private includeDateDialog: CustomDialogController = new CustomDialogController({
    builder: TitlePositionDialog({
      selected: this.includeDatePosition,
      onPick: (position: string): void => {
        this.setIncludeDatePosition(position).catch((e: Error) => {
          console.error(`SettingsPage include-date pick failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });
  private includeTimeDialog: CustomDialogController = new CustomDialogController({
    builder: TitlePositionDialog({
      selected: this.includeTimePosition,
      onPick: (position: string): void => {
        this.setIncludeTimePosition(position).catch((e: Error) => {
          console.error(`SettingsPage include-time pick failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.reloadSettings();
  }

  aboutToDisappear(): void {
    this.pageDisposed = true;
  }

  onPageShow(): void {
    if (this.initialized) {
      this.reloadSettings();
    }
  }

  private async reloadSettings(): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.loadState = SettingsLoadState.LOADING;
    this.saveBusy = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const store: EditorSettingsStore = new EditorSettingsStore(context);
      const enabled: boolean = await store.getShapeDetectionEnabled();
      const keepAwake: boolean = await store.getKeepDeviceAwake();
      const hideStatus: boolean = await store.getHideStatusBar();
      const hideNav: boolean = await store.getHideNavigationBar();
      const nightMode: boolean = await store.getNoteViewNightMode();
      const autoDeselect: boolean = await store.getAutoDeselectEraser();
      const palmDetection: boolean = await store.getPalmDetectionEnabled();
      const straightLines: boolean = await store.getStraightLinesEnabled();
      const undoRedoTaps: boolean = await store.getUndoRedoTapsEnabled();
      const rulerUnits: string = await store.getRulerUnits();
      const noteTitle: string | null = await store.getDefaultNoteTitle();
      const datePosition: string = await store.getIncludeDatePosition();
      const timePosition: string = await store.getIncludeTimePosition();
      const languageStore: OriginalHandwritingLanguagePreferenceStore =
        new OriginalHandwritingLanguagePreferenceStore(context);
      const storedLanguage: string | null = await languageStore.getRecognitionLanguageId();
      if (this.pageDisposed || generation !== this.loadGeneration) {
        return;
      }
      this.store = store;
      this.shapeDetectionEnabled = enabled;
      this.keepDeviceAwakeEnabled = keepAwake;
      this.hideStatusBarEnabled = hideStatus;
      this.hideNavigationBarEnabled = hideNav;
      this.noteViewNightModeEnabled = nightMode;
      this.autoDeselectEraserEnabled = autoDeselect;
      this.palmDetectionEnabled = palmDetection;
      this.straightLinesEnabled = straightLines;
      this.undoRedoTapsEnabled = undoRedoTaps;
      this.rulerUnits = rulerUnits;
      this.defaultNoteTitle = noteTitle === null ? '' : noteTitle;
      this.includeDatePosition = datePosition;
      this.includeTimePosition = timePosition;
      this.noteTitleExampleTs = Date.now();
      this.languageStore = languageStore;
      this.recognitionLanguageCode = resolveOriginalHandwritingLanguage(
        null, storedLanguage, readHarmonyOriginalHandwritingLocale()).localeCode;
      this.loadState = SettingsLoadState.READY;
      this.initialized = true;
    } catch (e) {
      if (this.pageDisposed || generation !== this.loadGeneration) {
        return;
      }
      this.store = null;
      this.loadState = SettingsLoadState.ERROR;
      this.initialized = true;
      console.error(`SettingsPage load failed: ${JSON.stringify(e)}`);
    }
  }

  // 原版 r22 case 2：note-editor 设置区 "Keep device awake" 开关，
  // 与 shape detection 同一乐观更新+回滚+生命周期守护模式。
  private async setKeepDeviceAwakeEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.keepDeviceAwakeEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.keepDeviceAwakeEnabled;
    this.keepDeviceAwakeEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveKeepDeviceAwake(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.keepDeviceAwakeEnabled = previous;
      console.error(`SettingsPage keep-awake save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 r22 case 1：note view night mode（纸墨深色外观）开关。
  private async setNoteViewNightModeEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.noteViewNightModeEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.noteViewNightModeEnabled;
    this.noteViewNightModeEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveNoteViewNightMode(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.noteViewNightModeEnabled = previous;
      console.error(`SettingsPage night-mode save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 ncn.a→su2→hpb(z)→epb：default_note_title 字段每次变更即写入
  // noteEditorSettings（键缺失=未设置→组装时用 fallback；清空即存 ''）。
  // 文本走直写（打字态不做 saveBusy 门/回滚——回滚会打断输入），失败仅 toast。
  private async setDefaultNoteTitle(title: string): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY) {
      return;
    }
    try {
      await store.saveDefaultNoteTitle(title);
    } catch (e) {
      if (this.pageDisposed) {
        return;
      }
      console.error(`SettingsPage default-title save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    }
  }

  // 原版 ibb：include_date 三态选择器（None/Prefix/Suffix → hpb→epb 写库）。
  private async setIncludeDatePosition(position: string): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      position === this.includeDatePosition) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: string = this.includeDatePosition;
    this.includeDatePosition = position;
    this.saveBusy = true;
    try {
      await store.saveIncludeDatePosition(position);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.includeDatePosition = previous;
      console.error(`SettingsPage include-date save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 ibb：include_time 三态选择器，同一守护模式。
  private async setIncludeTimePosition(position: string): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      position === this.includeTimePosition) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: string = this.includeTimePosition;
    this.includeTimePosition = position;
    this.saveBusy = true;
    try {
      await store.saveIncludeTimePosition(position);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.includeTimePosition = previous;
      console.error(`SettingsPage include-time save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 ibb 尾部显示：位置值 → 本地化 none/prefix/suffix 标签。
  private titlePositionLabel(position: string): Resource {
    if (position === NOTE_TITLE_POSITION_PREFIX) {
      return $r('app.string.title_position_prefix');
    }
    if (position === NOTE_TITLE_POSITION_SUFFIX) {
      return $r('app.string.title_position_suffix');
    }
    return $r('app.string.title_position_none');
  }

  // 原版 a96：example 预览 = mcn.g(草稿字段值, includeDate, includeTime,
  // remember{now})——草稿 blank 时只剩日期/时间分量（标题 fallback 不参与预览）。
  private noteTitleExample(): string {
    return formatOriginalAutoNoteTitle(this.defaultNoteTitle, '',
      this.includeDatePosition, this.includeTimePosition,
      this.noteTitleExampleTs === 0 ? Date.now() : this.noteTitleExampleTs);
  }

  // 原版 x22 case 3：auto_deselect_eraser 开关，同一守护模式。
  private async setAutoDeselectEraserEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.autoDeselectEraserEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.autoDeselectEraserEnabled;
    this.autoDeselectEraserEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveAutoDeselectEraser(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.autoDeselectEraserEnabled = previous;
      console.error(`SettingsPage auto-deselect-eraser save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 x22 case 0：straight_lines 开关，同一守护模式。
  private async setStraightLinesEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.straightLinesEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.straightLinesEnabled;
    this.straightLinesEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveStraightLinesEnabled(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.straightLinesEnabled = previous;
      console.error(`SettingsPage straight-lines save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 kd4 case 15 / o8b.P：undoRedoTapsEnabled —— 双指轻点撤销、
  // 三指轻点重做。同一乐观更新+回滚+生命周期守护模式。
  private async setUndoRedoTapsEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.undoRedoTapsEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.undoRedoTapsEnabled;
    this.undoRedoTapsEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveUndoRedoTapsEnabled(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.undoRedoTapsEnabled = previous;
      console.error(`SettingsPage undo-redo-taps save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 x22 case 4 / n94：ruler_units 选择——点选写入 o59.n（oof.I 序列化），
  // 同一乐观更新+回滚+生命周期守护模式。
  private async setRulerUnits(units: string): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      (units !== RULER_UNITS_IMPERIAL && units !== RULER_UNITS_METRIC) ||
      units === this.rulerUnits) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: string = this.rulerUnits;
    this.rulerUnits = units;
    this.saveBusy = true;
    try {
      await store.saveRulerUnits(units);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.rulerUnits = previous;
      console.error(`SettingsPage ruler-units save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 x22 case 2：palm_detection 开关，同一守护模式。
  private async setPalmDetectionEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.palmDetectionEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.palmDetectionEnabled;
    this.palmDetectionEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.savePalmDetectionEnabled(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.palmDetectionEnabled = previous;
      console.error(`SettingsPage palm-detection save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 r22 case 3：note view 隐藏状态栏开关，同一守护模式。
  private async setHideStatusBarEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.hideStatusBarEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.hideStatusBarEnabled;
    this.hideStatusBarEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveHideStatusBar(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.hideStatusBarEnabled = previous;
      console.error(`SettingsPage hide-status-bar save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 r22 case 4：note view 隐藏导航条开关，同一守护模式。
  private async setHideNavigationBarEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.hideNavigationBarEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.hideNavigationBarEnabled;
    this.hideNavigationBarEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveHideNavigationBar(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.hideNavigationBarEnabled = previous;
      console.error(`SettingsPage hide-navigation-bar save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  private async setShapeDetectionEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.shapeDetectionEnabled) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: boolean = this.shapeDetectionEnabled;
    this.shapeDetectionEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveShapeDetectionEnabled(enabled);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.shapeDetectionEnabled = previous;
      console.error(`SettingsPage save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 x22 case 5：language 行——手写识别语言选择（dc5 枚举，vmc 选择器
  // 写全局偏好）。持久化复用已移植的 OriginalHandwritingLanguagePreferenceStore
  //（写 dc5.I localeCode，与识别管线同一来源）。
  private async setRecognitionLanguage(localeCode: string): Promise<void> {
    const store: OriginalHandwritingLanguagePreferenceStore | null = this.languageStore;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      localeCode === this.recognitionLanguageCode) {
      return;
    }
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    const previous: string = this.recognitionLanguageCode;
    this.recognitionLanguageCode = localeCode;
    this.saveBusy = true;
    try {
      await store.saveRecognitionLanguageId(localeCode);
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
    } catch (e) {
      if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.recognitionLanguageCode = previous;
      console.error(`SettingsPage language save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.editor_setting_save_failed') });
      } catch (toastError) {
        console.error(`SettingsPage toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.saveBusy = false;
    }
  }

  // 原版 Appearance 区（r22 case 0 + dark_theme 行）：match_system_appearance
  // 开关对应 nve.MATCH_SYSTEM；关闭后 Dark theme 行在 LIGHT/DARK 间切换。
  // 持久化沿用 library_prefs/theme_mode（与 LibraryPage.setThemeMode 同路径）。
  private applyThemeMode(mode: ThemeMode): void {
    if (this.pageDisposed) {
      return;
    }
    ThemeStore.setMode(mode);
    const lifecycleGeneration: number = ++this.lifecycleGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        if (this.pageDisposed || lifecycleGeneration !== this.lifecycleGeneration) {
          return;
        }
        pref.putSync(THEME_PREFERENCE_KEY, mode);
        pref.flush().catch((e: Object): void => {
          console.error(`SettingsPage theme pref flush failed: ${JSON.stringify(e)}`);
        });
      }).catch((e: Object): void => {
        console.error(`SettingsPage theme pref failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      console.error(`SettingsPage applyThemeMode failed: ${JSON.stringify(e)}`);
    }
  }

  // match_system_appearance 开关：开 → system；关 → 保持当前视觉（跟随
  // 系统深浅色落为显式 light/dark，避免闪烁回跳）。
  private setMatchSystemAppearance(enabled: boolean): void {
    if (enabled) {
      this.applyThemeMode('system');
    } else {
      this.applyThemeMode(this.systemDark ? 'dark' : 'light');
    }
  }

  // dark_theme 开关：仅在非跟随系统时可用（match 覆盖显式选择）。
  private setDarkThemeEnabled(enabled: boolean): void {
    this.applyThemeMode(enabled ? 'dark' : 'light');
  }

  private openBackup(): void {
    router.pushUrl({ url: 'ui/settings/BackupPage' }).catch((e: Error) => {
      console.error(`SettingsPage push BackupPage failed: ${JSON.stringify(e)}`);
    });
  }

  private openDefaultTemplate(): void {
    router.pushUrl({ url: 'ui/settings/DefaultTemplatePage' }).catch((e: Error) => {
      console.error(`SettingsPage push DefaultTemplatePage failed: ${JSON.stringify(e)}`);
    });
  }

  private openRecentlyDeleted(): void {
    router.pushUrl({ url: 'ui/settings/RecentlyDeletedPage' }).catch((e: Error) => {
      console.error(`SettingsPage push RecentlyDeletedPage failed: ${JSON.stringify(e)}`);
    });
  }

  // 原版 j1/t0 URL 分发：k1.z() 协程 emit → startActivity；Harmony 用 openLink。
  private openExternalLink(url: string): void {
    const context = getContext(this) as common.UIAbilityContext;
    context.openLink(url).catch((e: Error) => {
      console.error(`SettingsPage openLink failed: ${JSON.stringify(e)}`);
    });
  }

  build() {
    Column() {
      Row() {
        Button() {
          // 原版返回 = ui_designsystem__back_arrow（ue4.r，go5.b 单色调）。
          ToolGlyph({
            glyph: 'back_arrow',
            contentColor: this.resolveTokens().textPrimary,
            iconSize: 22,
          })
        }
          .width(48)
          .height(40)
          .accessibilityText($r('app.string.back'))
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.settings'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 16 })

      if (this.loadState === SettingsLoadState.LOADING) {
        Row() {
          LoadingProgress().width(22).height(22)
          Text($r('app.string.settings_loading'))
            .fontSize(14)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ left: 8 })
        }
        .margin({ top: 24 })
      } else if (this.loadState === SettingsLoadState.ERROR) {
        Column() {
          Text($r('app.string.settings_load_failed'))
            .fontSize(14)
            .fontColor(this.resolveTokens().danger)
            .margin({ bottom: 12 })
          Button($r('app.string.retry'))
            .onClick(() => {
              if (this.saveBusy) {
                return;
              }
              this.reloadSettings();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24 })
      } else {
        Scroll() {
          Column() {
            // 原版 s3d 设置目录顺序：appearance 先于 note_editor。
            Text($r('app.string.appearance'))
              .width('100%')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ bottom: 8 })

            // 原版 r22 case 0：match_system_appearance（nve.MATCH_SYSTEM）。
            Row() {
              Text($r('app.string.match_system_appearance'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Toggle({ type: ToggleType.Switch, isOn: this.themeMode === 'system' })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setMatchSystemAppearance(enabled);
                })
            }
            .width('100%')
            .height(56)
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 g8 dark_theme 行：match 开启时被覆盖，禁用。
            Row() {
              Text($r('app.string.dark_theme'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
                .opacity(this.themeMode === 'system' ? 0.4 : 1)
              Toggle({ type: ToggleType.Switch, isOn: this.themeMode === 'dark' })
                .enabled(!this.saveBusy && this.themeMode !== 'system')
                .opacity(this.themeMode === 'system' ? 0.4 : 1)
                .onChange((enabled: boolean) => {
                  this.setDarkThemeEnabled(enabled);
                })
            }
            .width('100%')
            .height(56)
            .margin({ top: 8 })
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.resolveTokens().surface)

            Text($r('app.string.note_editor'))
              .width('100%')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ top: 24, bottom: 8 })

            // 原版 x22 case 0：straight_lines + description（画线后按住自动拉直）。
            Row() {
              Column() {
                Text($r('app.string.straight_lines'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.straight_lines_description'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.straightLinesEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setStraightLinesEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 x22 case 1：shapes_detection + description（画形状按住自动识别）。
            Row() {
              Column() {
                Text($r('app.string.shape_detection'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.shape_detection_description'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.shapeDetectionEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setShapeDetectionEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 x22 case 2：palm_detection + description（书写时可放手掌）。
            Row() {
              Column() {
                Text($r('app.string.palm_detection'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.palm_detection_description'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.palmDetectionEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setPalmDetectionEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 x22 case 3：auto_deselect_eraser + description（擦除后切回上个工具）。
            Row() {
              Column() {
                Text($r('app.string.auto_deselect_eraser'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.auto_deselect_eraser_description'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.autoDeselectEraserEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setAutoDeselectEraserEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 kd4 case 15 / o8b.P：two_finger_tap + description
            //（双指轻点撤销、三指轻点重做；缺省 true）。
            Row() {
              Column() {
                Text($r('app.string.two_finger_tap'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.two_finger_tap_description'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.undoRedoTapsEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setUndoRedoTapsEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 x22 case 4：ruler_units 行——尾部显示当前单位
            //（vnh.c → feature_settings__imperial/metric），点击打开
            // n94 单位选择器。原版尺具虽被 s01.a0 隐藏，该行仍可见。
            Row() {
              Column() {
                Text($r('app.string.ruler_units'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Text(this.rulerUnits === RULER_UNITS_METRIC
                ? $r('app.string.metric')
                : $r('app.string.imperial'))
                .fontSize(14)
                .fontColor(this.resolveTokens().textSecondary)
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)
            .onClick(() => {
              if (!this.saveBusy) {
                this.rulerUnitsDialog.open();
              }
            })

            // 原版 x22 case 5：language 行——尾部显示当前识别语言名
            //（pb5 case 0 用 dc5→显示名映射），点击打开语言选择器。
            Row() {
              Column() {
                Text($r('app.string.language'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.handwriting_language_caption'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Text(originalHandwritingLanguageDisplayName(this.recognitionLanguageCode))
                .fontSize(14)
                .fontColor(this.resolveTokens().textSecondary)
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)
            .onClick(() => {
              if (!this.saveBusy) {
                this.languageDialog.open();
              }
            })

            // 原版 e8b→document_defaults→note_title 子屏（c1 case2 →
            // ncn.a/yob/ibb/a96）：自定义默认标题 + 日期/时间位置 + 示例。
            Text($r('app.string.document_defaults'))
              .width('100%')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ top: 24, bottom: 8 })

            Column() {
              Text($r('app.string.default_note_title'))
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Stack({ alignContent: Alignment.End }) {
                TextInput({
                  placeholder: $r('app.string.default_note_title_fallback'),
                  text: this.defaultNoteTitle,
                })
                  .width('100%')
                  .fontColor(this.resolveTokens().textPrimary)
                  .placeholderColor(this.resolveTokens().textSecondary)
                  .backgroundColor(this.resolveTokens().control)
                  .padding({ right: 34 })
                  // 原版 je case11：草稿 ≤200 UTF-16 码元才入 state。
                  .maxLength(200)
                  .onChange((value: string) => {
                    this.defaultNoteTitle = value;
                    this.setDefaultNoteTitle(value).catch((e: Error) => {
                      console.error(`SettingsPage title save failed: ${JSON.stringify(e)}`);
                    });
                  })
                if (this.defaultNoteTitle.length > 0) {
                  // 原版 yob case0：字段非空时尾部 xmark_circle_fill 清除钮
                  //（ui_designsystem__clear cd），点击清空输入。
                  Button() {
                    Stack() {
                      Row()
                        .width(15)
                        .height(15)
                        .borderRadius(7.5)
                        .backgroundColor(this.resolveTokens().textSecondary)
                      ToolGlyph({
                        glyph: 'close_med_regular',
                        contentColor: this.resolveTokens().control,
                        iconSize: 9,
                      })
                    }
                  }
                    .width(28)
                    .height(28)
                    .backgroundColor(Color.Transparent)
                    .margin({ right: 4 })
                    .accessibilityText($r('app.string.clear_field'))
                    .onClick(() => {
                      this.defaultNoteTitle = '';
                      this.setDefaultNoteTitle('').catch((e: Error) => {
                        console.error(`SettingsPage title clear failed: ${JSON.stringify(e)}`);
                      });
                    })
                }
              }
              .margin({ top: 8 })

              // 原版 yob case1：include_date 行（ibb 三态选择器）。
              Row() {
                Text($r('app.string.include_date'))
                  .layoutWeight(1)
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text(this.titlePositionLabel(this.includeDatePosition))
                  .fontSize(14)
                  .fontColor(this.resolveTokens().textSecondary)
              }
              .width('100%')
              .height(44)
              .margin({ top: 8 })
              .onClick(() => {
                if (!this.saveBusy) {
                  this.includeDateDialog.open();
                }
              })

              // 原版 yob default：include_time 行。
              Row() {
                Text($r('app.string.include_time'))
                  .layoutWeight(1)
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text(this.titlePositionLabel(this.includeTimePosition))
                  .fontSize(14)
                  .fontColor(this.resolveTokens().textSecondary)
              }
              .width('100%')
              .height(44)
              .margin({ top: 8 })
              .onClick(() => {
                if (!this.saveBusy) {
                  this.includeTimeDialog.open();
                }
              })

              // 原版 a96："Example:" + 实时 mcn.g(草稿, 位置, 进屏时刻)
              //（原版 cle.p 空格拼接；ArkUI 用同行双 Text + 间距等价）。
              Row() {
                Text($r('app.string.example_label'))
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textSecondary)
                Text(this.noteTitleExample())
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ left: 4 })
              }
              .width('100%')
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(12)
            .margin({ top: 8 })
            .backgroundColor(this.resolveTokens().surface)
            .alignItems(HorizontalAlign.Start)

            // 原版 r22 case 2：note-editor 设置区第二项 "Keep device awake"。
            Row() {
              Text($r('app.string.keep_device_awake'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Toggle({ type: ToggleType.Switch, isOn: this.keepDeviceAwakeEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setKeepDeviceAwakeEnabled(enabled);
                })
            }
            .width('100%')
            .height(56)
            .margin({ top: 8 })
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 r22 case 3/4：note view 隐藏状态栏/导航条开关。
            Row() {
              Text($r('app.string.hide_status_bar'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Toggle({ type: ToggleType.Switch, isOn: this.hideStatusBarEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setHideStatusBarEnabled(enabled);
                })
            }
            .width('100%')
            .height(56)
            .margin({ top: 8 })
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.resolveTokens().surface)
            Row() {
              Text($r('app.string.hide_navigation_bar'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Toggle({ type: ToggleType.Switch, isOn: this.hideNavigationBarEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setHideNavigationBarEnabled(enabled);
                })
            }
            .width('100%')
            .height(56)
            .margin({ top: 8 })
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.resolveTokens().surface)

            // 原版 r22 case 1：note_view_night_mode + caption（纸墨深色外观）。
            Row() {
              Column() {
                Text($r('app.string.note_view_night_mode'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textPrimary)
                Text($r('app.string.note_view_night_mode_caption'))
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.noteViewNightModeEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setNoteViewNightModeEnabled(enabled);
                })
            }
            .width('100%')
            .margin({ top: 8 })
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.resolveTokens().surface)

            Button($r('app.string.default_template'))
              .width('100%')
              .height(48)
              .margin({ top: 12 })
              .onClick(() => {
                this.openDefaultTemplate();
              })

            Button($r('app.string.recently_deleted'))
              .width('100%')
              .height(48)
              .margin({ top: 12 })
              .onClick(() => {
                this.openRecentlyDeleted();
              })

            Divider()
              .color(this.resolveTokens().border)
              .margin({ top: 24, bottom: 24 })

            Button($r('app.string.backup_and_sync'))
              .width('100%')
              .height(48)
              .onClick(() => {
                this.openBackup();
              })

            // 原版 xpa About 区（yrm.a + v0(1)→wxm.a→s0 列表）：
            // [Blog 钮] + [Discord 卡] + [社交图标行]。
            // rate_notability → play.google.com（Android 商店页无 Harmony 等价）
            // 与 h35.Y0 flag 门控的 Newsletter/Threads 文本钮均 fail-closed。
            Text($r('app.string.feature_settings__about'))
              .width('100%')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ top: 24, bottom: 8 })

            Button($r('app.string.feature_settings__blog'))
              .width('100%')
              .height(48)
              .onClick(() => {
                this.openExternalLink('https://blog.notability.com');
              })

            // 原版 wxm.b/u0 case3 Discord 卡（tee.a 16dp 内边距）：
            // 标题 + 描述 + [Accept invite 主钮 | Learn more 次钮]。
            Column() {
              Text($r('app.string.feature_settings__discord_title'))
                .width('100%')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.resolveTokens().textPrimary)
              Text($r('app.string.feature_settings__discord_description'))
                .width('100%')
                .fontSize(14)
                .fontColor(this.resolveTokens().textSecondary)
                .margin({ top: 4 })
              Row() {
                Button($r('app.string.feature_settings__discord_accept_invite'))
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor(this.resolveTokens().accent)
                  .fontColor(this.resolveTokens().onAccent)
                  .onClick(() => {
                    this.openExternalLink('https://discord.gg/Fw9SsRYU7a');
                  })
                Button($r('app.string.feature_settings__discord_learn_more'))
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor(this.resolveTokens().control)
                  .fontColor(this.resolveTokens().textPrimary)
                  .margin({ left: 12 })
                  .onClick(() => {
                    this.openExternalLink('https://support.gingerlabs.com/hc/en-us/articles/5459034545178-Join-the-Notability-Discord-Server');
                  })
              }
              .width('100%')
              .margin({ top: 12 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 8 })
            .padding(16)
            .backgroundColor(this.resolveTokens().surface)

            // 原版 wxm.c：五枚 cc3.l 图标钮，cd = feature_settings__cd_*。
            Row() {
              ForEach(this.socialLinks, (item: SocialLinkSpec) => {
                Button() {
                  ToolGlyph({
                    glyph: item.glyph,
                    contentColor: this.resolveTokens().textPrimary,
                    iconSize: 24,
                  })
                }
                  .width(48)
                  .height(48)
                  .margin({ left: 8, right: 8 })
                  .accessibilityText(item.label)
                  .onClick(() => {
                    this.openExternalLink(item.url);
                  })
              }, (item: SocialLinkSpec) => item.glyph)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }
}

// 原版 vmc 手写识别语言选择器：dc5 枚举顺序列出全部 23 种语言，
// 当前语言显示选中标记，点选即写全局偏好并关闭。
@CustomDialog
struct HandwritingLanguageDialog {
  controller?: CustomDialogController;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  selected: string = ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE;
  options: OriginalHandwritingLanguageOption[] =
    originalHandwritingRecognitionLanguageOptions();
  onPick: (localeCode: string) => void = (_localeCode: string): void => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text($r('app.string.language'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ bottom: 8 })
      Scroll() {
        Column() {
          ForEach(this.options, (option: OriginalHandwritingLanguageOption) => {
            Row() {
              Text(option.displayName)
                .layoutWeight(1)
                .fontSize(15)
                .fontColor(this.resolveTokens().textPrimary)
              if (option.localeCode === this.selected) {
                // 原版选中指示 = ui_designsystem__general_check_med_reg。
                ToolGlyph({
                  glyph: 'general_check_med_reg',
                  contentColor: this.resolveTokens().accent,
                  iconSize: 15,
                })
              }
            }
            .width('100%')
            .height(44)
            .padding({ left: 8, right: 8 })
            .onClick(() => {
              if (this.controller !== undefined) {
                this.controller.close();
              }
              this.onPick(option.localeCode);
            })
          }, (option: OriginalHandwritingLanguageOption): string => option.localeCode)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(360)
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}

interface RulerUnitsOption {
  units: string;
  label: Resource;
}

// 原版 n94：ruler_units 单位选择器，oof.N 顺序 Imperial→Metric，
// 当前项显示选中标记，点选经 vc→wb5 写 o59.n 并关闭。
@CustomDialog
struct RulerUnitsDialog {
  controller?: CustomDialogController;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  selected: string = DEFAULT_RULER_UNITS;
  options: RulerUnitsOption[] = [
    { units: RULER_UNITS_IMPERIAL, label: $r('app.string.imperial') },
    { units: RULER_UNITS_METRIC, label: $r('app.string.metric') },
  ];
  onPick: (units: string) => void = (_units: string): void => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text($r('app.string.ruler_units'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ bottom: 8 })
      Column() {
        ForEach(this.options, (option: RulerUnitsOption) => {
          Row() {
            Text(option.label)
              .layoutWeight(1)
              .fontSize(15)
              .fontColor(this.resolveTokens().textPrimary)
            if (option.units === this.selected) {
              // 原版选中指示 = ui_designsystem__general_check_med_reg。
              ToolGlyph({
                glyph: 'general_check_med_reg',
                contentColor: this.resolveTokens().accent,
                iconSize: 15,
              })
            }
          }
          .width('100%')
          .height(44)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            if (this.controller !== undefined) {
              this.controller.close();
            }
            this.onPick(option.units);
          })
        }, (option: RulerUnitsOption): string => option.units)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}

// 原版 ibb：include_date/include_time 行的 None/Prefix/Suffix 三态选择器
//（下拉弹层语义；Harmony 用与 n94 一致的 CustomDialog + 选中勾）。
interface TitlePositionOption {
  position: string;
  label: Resource;
}

@CustomDialog
struct TitlePositionDialog {
  controller?: CustomDialogController;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  selected: string = NOTE_TITLE_POSITION_NONE;
  options: TitlePositionOption[] = [
    { position: NOTE_TITLE_POSITION_NONE, label: $r('app.string.title_position_none') },
    { position: NOTE_TITLE_POSITION_PREFIX, label: $r('app.string.title_position_prefix') },
    { position: NOTE_TITLE_POSITION_SUFFIX, label: $r('app.string.title_position_suffix') },
  ];
  onPick: (position: string) => void = (_position: string): void => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      ForEach(this.options, (option: TitlePositionOption) => {
        Row() {
          Text(option.label)
            .layoutWeight(1)
            .fontSize(15)
            .fontColor(this.resolveTokens().textPrimary)
          if (option.position === this.selected) {
            // 原版选中指示 = ui_designsystem__general_check_med_reg。
            ToolGlyph({
              glyph: 'general_check_med_reg',
              contentColor: this.resolveTokens().accent,
              iconSize: 15,
            })
          }
        }
        .width('100%')
        .height(44)
        .padding({ left: 8, right: 8 })
        .onClick(() => {
          if (this.controller !== undefined) {
            this.controller.close();
          }
          this.onPick(option.position);
        })
      }, (option: TitlePositionOption): string => option.position)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}
