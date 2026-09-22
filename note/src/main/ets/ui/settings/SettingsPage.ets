import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import {
  DEFAULT_AUTO_DESELECT_ERASER, DEFAULT_HIDE_NAVIGATION_BAR, DEFAULT_HIDE_STATUS_BAR,
  DEFAULT_KEEP_DEVICE_AWAKE, DEFAULT_NOTE_VIEW_NIGHT_MODE, DEFAULT_PALM_DETECTION,
  DEFAULT_SHAPE_DETECTION_ENABLED, EditorSettingsStore,
} from '../../data/EditorSettingsStore';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

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
  @State saveBusy: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private store: EditorSettingsStore | null = null;
  private initialized: boolean = false;
  private loadGeneration: number = 0;
  private lifecycleGeneration: number = 0;
  private pageDisposed: boolean = false;

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
            Text($r('app.string.note_editor'))
              .width('100%')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ bottom: 8 })

            Row() {
              Text($r('app.string.shape_detection'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor(this.resolveTokens().textPrimary)
              Toggle({ type: ToggleType.Switch, isOn: this.shapeDetectionEnabled })
                .enabled(!this.saveBusy)
                .onChange((enabled: boolean) => {
                  this.setShapeDetectionEnabled(enabled);
                })
            }
            .width('100%')
            .height(56)
            .padding({ left: 12, right: 12 })
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
