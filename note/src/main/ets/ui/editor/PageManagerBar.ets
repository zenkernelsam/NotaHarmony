import { NoteBackgroundSettings } from '../../core/model/NoteTypes';
import { originalDefaultNoteBackgroundSettings } from '../../core/model/PageBackgroundModel';
import { PageSettingsPanel } from '../components/PageSettingsPanel';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

interface PopupStateChangeEvent {
  isVisible: boolean;
}

@Component
export struct PageManagerBar {
  @Prop currentPageIndex: number = 0;
  @Prop pageCount: number = 1;
  @Prop busy: boolean = false;
  @Prop noteBackground: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
  @State showSettings: boolean = false;
  @State compact: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  onPrev: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onAdd: () => void = () => {
  };
  onDelete: () => void = () => {
  };
  onMovePrevious: () => void = () => {
  };
  onMoveNext: () => void = () => {
  };
  onApplyNoteBackground: (settings: NoteBackgroundSettings) => void = () => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Row() {
      this.NavigationButton('<', true)
      Text((this.currentPageIndex + 1) + ' / ' + this.pageCount)
        .fontSize(14)
        .width(this.compact ? 56 : 64)
        .textAlign(TextAlign.Center)
      this.NavigationButton('>', false)

      if (this.compact) {
        Blank()
        this.SettingsButton(true)
        Button('+')
          .width(44)
          .height(40)
          .fontSize(20)
          .enabled(!this.busy)
          .opacity(this.busy ? 0.4 : 1)
          .accessibilityText($r('app.string.add_page'))
          .onClick(() => {
            this.onAdd();
          })
        Button('...')
          .height(40)
          .fontSize(12)
          .margin({ left: 4, right: 8 })
          .enabled(!this.busy)
          .accessibilityText($r('app.string.more_page_actions'))
          .bindMenu(this.buildPageMenu())
      } else {
        this.SettingsButton(false)
        Button($r('app.string.move_page_earlier'))
          .height(40)
          .margin({ left: 8 })
          .enabled(!this.busy && this.currentPageIndex > 0)
          .opacity(!this.busy && this.currentPageIndex > 0 ? 1 : 0.4)
          .onClick(() => {
            this.onMovePrevious();
          })
        Button($r('app.string.move_page_later'))
          .height(40)
          .margin({ left: 4 })
          .enabled(!this.busy && this.currentPageIndex < this.pageCount - 1)
          .opacity(!this.busy && this.currentPageIndex < this.pageCount - 1 ? 1 : 0.4)
          .onClick(() => {
            this.onMoveNext();
          })
        Blank()
        Button($r('app.string.add_page'))
          .height(40)
          .margin({ left: 8, right: 8 })
          .enabled(!this.busy)
          .opacity(this.busy ? 0.4 : 1)
          .onClick(() => {
            this.onAdd();
          })
        Button($r('app.string.delete'))
          .height(40)
          .margin({ left: 4, right: 16 })
          .enabled(!this.busy && this.pageCount > 1)
          .opacity(!this.busy && this.pageCount > 1 ? 1 : 0.4)
          .onClick(() => {
            this.onDelete();
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: this.compact ? 4 : 8 })
    .backgroundColor(this.resolveTokens().surface)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.compact = (newArea.width as number) < 600;
    })
  }

  @Builder
  NavigationButton(label: string, previous: boolean) {
    Button(label)
      .width(44)
      .height(40)
      .margin({ left: 4, right: 4 })
      .enabled(!this.busy && (previous ? this.currentPageIndex > 0 :
        this.currentPageIndex < this.pageCount - 1))
      .opacity(!this.busy && (previous ? this.currentPageIndex > 0 :
        this.currentPageIndex < this.pageCount - 1) ? 1 : 0.4)
      .accessibilityText(previous ? $r('app.string.previous_page') : $r('app.string.next_page'))
      .onClick(() => {
        if (previous) {
          this.onPrev();
        } else {
          this.onNext();
        }
      })
  }

  @Builder
  SettingsButton(compact: boolean) {
    Button($r('app.string.page_settings'))
      .height(40)
      .fontSize(13)
      .margin({ left: 8 })
      .enabled(!this.busy)
      .opacity(this.busy ? 0.4 : 1)
      .onClick(() => {
        this.showSettings = true;
      })
      .bindPopup(this.showSettings, {
        builder: (): void => {
          this.PageSettingsBuilder()
        },
        placement: Placement.Top,
        onStateChange: (event: PopupStateChangeEvent) => {
          this.showSettings = event.isVisible;
        },
      })
  }

  private buildPageMenu(): MenuElement[] {
    return [
      { value: $r('app.string.move_page_earlier'), action: () => {
        if (!this.busy && this.currentPageIndex > 0) {
          this.onMovePrevious();
        }
      } },
      { value: $r('app.string.move_page_later'), action: () => {
        if (!this.busy && this.currentPageIndex < this.pageCount - 1) {
          this.onMoveNext();
        }
      } },
      { value: $r('app.string.delete_page'), action: () => {
        if (!this.busy && this.pageCount > 1) {
          this.onDelete();
        }
      } },
    ];
  }

  @Builder
  PageSettingsBuilder() {
    PageSettingsPanel({
      settings: this.noteBackground,
      busy: this.busy,
      onApply: (settings: NoteBackgroundSettings) => {
        this.onApplyNoteBackground(settings);
      },
    })
  }
}
