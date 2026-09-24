import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import {
  DEFAULT_AUTO_DESELECT_ERASER, DEFAULT_HIDE_NAVIGATION_BAR, DEFAULT_HIDE_STATUS_BAR,
  DEFAULT_KEEP_DEVICE_AWAKE, DEFAULT_NOTE_VIEW_NIGHT_MODE, DEFAULT_PALM_DETECTION,
  DEFAULT_RULER_UNITS, DEFAULT_SHAPE_DETECTION_ENABLED, DEFAULT_STRAIGHT_LINES,
  EditorSettingsStore, RULER_UNITS_IMPERIAL, RULER_UNITS_METRIC,
} from '../../data/EditorSettingsStore';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';
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
  @State rulerUnits: string = DEFAULT_RULER_UNITS;
  @State recognitionLanguageCode: string = ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE;
  @State saveBusy: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private store: EditorSettingsStore | null = null;
  private languageStore: OriginalHandwritingLanguagePreferenceStore | null = null;
  private initialized: boolean = false;
  private loadGeneration: number = 0;
  private lifecycleGeneration: number = 0;
  private pageDisposed: boolean = false;
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
      const rulerUnits: string = await store.getRulerUnits();
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
      this.rulerUnits = rulerUnits;
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

  build() {
    Column() {
      Row() {
        Button('<')
          .width(48)
          .height(40)
          .fontSize(20)
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
                Text('✓')
                  .fontSize(15)
                  .fontColor(this.resolveTokens().accent)
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
              Text('✓')
                .fontSize(15)
                .fontColor(this.resolveTokens().accent)
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
