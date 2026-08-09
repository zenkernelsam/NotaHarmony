import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import {
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
  @State saveBusy: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private store: EditorSettingsStore | null = null;
  private initialized: boolean = false;
  private loadGeneration: number = 0;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.reloadSettings();
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
      if (generation !== this.loadGeneration) {
        return;
      }
      this.store = store;
      this.shapeDetectionEnabled = enabled;
      this.loadState = SettingsLoadState.READY;
      this.initialized = true;
    } catch (e) {
      if (generation !== this.loadGeneration) {
        return;
      }
      this.store = null;
      this.loadState = SettingsLoadState.ERROR;
      this.initialized = true;
      console.error(`SettingsPage load failed: ${JSON.stringify(e)}`);
    }
  }

  private async setShapeDetectionEnabled(enabled: boolean): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== SettingsLoadState.READY || this.saveBusy ||
      enabled === this.shapeDetectionEnabled) {
      return;
    }
    const previous: boolean = this.shapeDetectionEnabled;
    this.shapeDetectionEnabled = enabled;
    this.saveBusy = true;
    try {
      await store.saveShapeDetectionEnabled(enabled);
    } catch (e) {
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
