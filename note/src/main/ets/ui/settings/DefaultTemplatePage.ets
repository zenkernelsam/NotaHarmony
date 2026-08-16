import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { NoteBackgroundSettings } from '../../core/model/NoteTypes';
import {
  originalDefaultTemplateFromSettings, originalDefaultTemplateSettings,
} from '../../core/model/OriginalDefaultTemplate';
import {
  cloneNoteBackgroundSettings, originalDefaultNoteBackgroundSettings,
  sameNoteBackgroundSettings,
} from '../../core/model/PageBackgroundModel';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import { PageSettingsPanel } from '../components/PageSettingsPanel';
import { ThemeMode, ThemeTokens } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

enum DefaultTemplateLoadState {
  LOADING = 'loading',
  ERROR = 'error',
  READY = 'ready',
}

@Entry
@Component
struct DefaultTemplatePage {
  @State loadState: DefaultTemplateLoadState = DefaultTemplateLoadState.LOADING;
  @State settings: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
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
    this.reloadDefaultTemplate();
  }

  onPageShow(): void {
    if (this.initialized) {
      this.reloadDefaultTemplate();
    }
  }

  private async reloadDefaultTemplate(): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.loadState = DefaultTemplateLoadState.LOADING;
    this.saveBusy = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const store: EditorSettingsStore = new EditorSettingsStore(context);
      const settings: NoteBackgroundSettings = originalDefaultTemplateSettings(
        await store.getSelectedDefaultTemplate());
      if (generation !== this.loadGeneration) {
        return;
      }
      this.store = store;
      this.settings = settings;
      this.loadState = DefaultTemplateLoadState.READY;
      this.initialized = true;
    } catch (e) {
      if (generation !== this.loadGeneration) {
        return;
      }
      this.store = null;
      this.loadState = DefaultTemplateLoadState.ERROR;
      this.initialized = true;
      console.error(`DefaultTemplatePage load failed: ${JSON.stringify(e)}`);
    }
  }

  private async saveDefaultTemplate(next: NoteBackgroundSettings): Promise<void> {
    const store: EditorSettingsStore | null = this.store;
    if (store === null || this.loadState !== DefaultTemplateLoadState.READY || this.saveBusy ||
      sameNoteBackgroundSettings(this.settings, next)) {
      return;
    }
    const previous: NoteBackgroundSettings = cloneNoteBackgroundSettings(this.settings);
    this.settings = cloneNoteBackgroundSettings(next);
    this.saveBusy = true;
    try {
      await store.saveSelectedDefaultTemplate(originalDefaultTemplateFromSettings(next));
      try {
        promptAction.showToast({ message: $r('app.string.default_template_saved'), duration: 1800 });
      } catch (_toastError) {
      }
    } catch (e) {
      this.settings = previous;
      console.error(`DefaultTemplatePage save failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.default_template_save_failed') });
      } catch (_toastError) {
      }
    } finally {
      this.saveBusy = false;
    }
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
        Text($r('app.string.default_template'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 16 })

      if (this.loadState === DefaultTemplateLoadState.LOADING) {
        Row() {
          LoadingProgress().width(22).height(22)
          Text($r('app.string.default_template_loading'))
            .fontSize(14)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ left: 8 })
        }
        .margin({ top: 24 })
      } else if (this.loadState === DefaultTemplateLoadState.ERROR) {
        Column() {
          Text($r('app.string.default_template_load_failed'))
            .fontSize(14)
            .fontColor(this.resolveTokens().danger)
            .margin({ bottom: 12 })
          Button($r('app.string.retry'))
            .onClick(() => {
              this.reloadDefaultTemplate();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24 })
      } else {
        Scroll() {
          Column() {
            Text($r('app.string.default_template_description'))
              .width('100%')
              .fontSize(14)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ bottom: 12 })
            PageSettingsPanel({
              settings: this.settings,
              busy: this.saveBusy,
              onApply: (settings: NoteBackgroundSettings) => {
                this.saveDefaultTemplate(settings);
              },
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
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
