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
  @Prop currentPageBookmarked: boolean = false;
  @Prop photoImportLeaseActive: boolean = false;
  @Prop busy: boolean = false;
  @Prop noteBackground: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
  @State showSettings: boolean = false;
  @State compact: boolean = false;
  private jumpDialog: CustomDialogController = new CustomDialogController({
    builder: JumpToPageDialog({
      pageCount: this.pageCount,
      initialValue: (this.currentPageIndex + 1).toString(),
      onGo: (pageIndex: number): void => {
        this.onJumpToPage(pageIndex);
      },
    }),
    autoCancel: true,
  });
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
  // Original content-manager bookmark toggle (de2.m / ae2): a single-page
  // selection flips its wz9.bookmarkedRegister value.
  onToggleBookmark: () => void = () => {
  };
  // Original zd2 case 1: the content-manager Rotate Page action steps the
  // page's nz9 rotation register through the cardinal cycle.
  onRotatePage: () => void = () => {
  };
  onClearPage: () => void = () => {
  };
  // Original ke1 case 20: the page indicator is clickable and opens the
  // jump-to-page dialog; Go applies the 1-based target page index.
  onJumpToPage: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  onApplyNoteBackground: (settings: NoteBackgroundSettings) => void = () => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Row() {
      this.NavigationButton('<', true)
      // Original ke1 case 20: tapping the page indicator opens the
      // jump-to-page dialog (fail-closed under busy/lease like siblings).
      Text((this.currentPageIndex + 1) + ' / ' + this.pageCount)
        .fontSize(14)
        .width(this.compact ? 56 : 64)
        .textAlign(TextAlign.Center)
        .enabled(!this.busy && !this.photoImportLeaseActive)
        // 原版 feature_note__page_indicator：页码指示器播报 "N of M"。
        .accessibilityText($r('app.string.cd_page_indicator',
          this.currentPageIndex + 1, this.pageCount))
        .onClick(() => {
          if (this.busy || this.photoImportLeaseActive) {
            return;
          }
          this.jumpDialog.open();
        })
      this.NavigationButton('>', false)
      if (this.currentPageBookmarked) {
        // md.java bookmark_tall_fill overlay parity: the page indicator marks
        // the current page when its wz9.bookmarkedRegister is BOOKMARKED.
        Text('🔖')
          .fontSize(14)
          .width(20)
          .accessibilityText($r('app.string.bookmark_page'))
      }

      if (this.compact) {
        Blank()
        this.SettingsButton(true)
        Button('+')
          .width(44)
          .height(40)
          .fontSize(20)
          .enabled(!this.busy && !this.photoImportLeaseActive)
          .opacity(this.busy ? 0.4 : 1)
          .accessibilityText($r('app.string.add_page'))
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onAdd();
          })
        Button('...')
          .width(44)
          .height(40)
          .fontSize(12)
          .margin({ left: 4, right: 8 })
          .enabled(!this.busy && !this.photoImportLeaseActive)
          .accessibilityText($r('app.string.more_page_actions'))
          .bindMenu(this.buildPageMenu())
      } else {
        this.SettingsButton(false)
        Button('🔖')
          .width(44)
          .height(40)
          .fontSize(16)
          .margin({ left: 8 })
          .enabled(!this.busy && !this.photoImportLeaseActive)
          .opacity(this.busy || this.photoImportLeaseActive ? 0.4 :
            (this.currentPageBookmarked ? 1 : 0.55))
          .fontColor(this.currentPageBookmarked ? this.resolveTokens().accent :
            this.resolveTokens().textPrimary)
          .accessibilityText($r('app.string.bookmark_page'))
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onToggleBookmark();
          })
        Button($r('app.string.move_page_earlier'))
          .height(40)
          .margin({ left: 8 })
          .enabled(!this.busy && this.currentPageIndex > 0)
          .opacity(!this.busy && this.currentPageIndex > 0 ? 1 : 0.4)
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onMovePrevious();
          })
        Button($r('app.string.move_page_later'))
          .height(40)
          .margin({ left: 4 })
          .enabled(!this.busy && this.currentPageIndex < this.pageCount - 1)
          .opacity(!this.busy && this.currentPageIndex < this.pageCount - 1 ? 1 : 0.4)
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onMoveNext();
          })
        Blank()
        Button($r('app.string.add_page'))
          .height(40)
          .margin({ left: 8, right: 8 })
          .enabled(!this.busy && !this.photoImportLeaseActive)
          .opacity(this.busy ? 0.4 : 1)
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onAdd();
          })
        Button($r('app.string.delete'))
          .height(40)
          .margin({ left: 4, right: 16 })
          .enabled(!this.busy && !this.photoImportLeaseActive &&
            this.pageCount > 1)
          .opacity(!this.busy && !this.photoImportLeaseActive &&
            this.pageCount > 1 ? 1 : 0.4)
          .onClick(() => {
            if (this.busy || this.photoImportLeaseActive) {
              return;
            }
            this.onDelete();
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: this.compact ? 4 : 8 })
    .backgroundColor(this.resolveTokens().surface)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      // The regular row contains two localized move actions.  Keep it out of
      // the 600vp tablet/phone width class; those actions remain available in
      // the native overflow menu below.
      this.compact = (newArea.width as number) < 720;
    })
  }

  @Builder
  NavigationButton(label: string, previous: boolean) {
    Button(label)
      .width(44)
      .height(40)
      .margin({ left: 4, right: 4 })
      .enabled(!this.busy && !this.photoImportLeaseActive &&
        (previous ? this.currentPageIndex > 0 :
        this.currentPageIndex < this.pageCount - 1))
      .opacity(!this.busy && !this.photoImportLeaseActive &&
        (previous ? this.currentPageIndex > 0 :
        this.currentPageIndex < this.pageCount - 1) ? 1 : 0.4)
      .accessibilityText(previous ? $r('app.string.previous_page') : $r('app.string.next_page'))
      .onClick(() => {
        if (this.busy || this.photoImportLeaseActive) {
          return;
        }
        if (previous) {
          this.onPrev();
        } else {
          this.onNext();
        }
      })
  }

  @Builder
  SettingsButton(compact: boolean) {
    Button(compact ? '⚙' : $r('app.string.page_settings'))
      .width(compact ? 44 : 112)
      .height(40)
      .fontSize(compact ? 20 : 13)
      .margin({ left: compact ? 2 : 8 })
      .enabled(!this.busy && !this.photoImportLeaseActive)
      .opacity(this.busy ? 0.4 : 1)
      .accessibilityText($r('app.string.page_settings'))
      .onClick(() => {
        if (this.busy || this.photoImportLeaseActive) {
          return;
        }
        this.showSettings = true;
      })
      .bindPopup(this.showSettings, {
        builder: (): void => {
          if (!this.photoImportLeaseActive) {
            this.PageSettingsBuilder()
          }
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
        if (!this.busy && !this.photoImportLeaseActive &&
          this.currentPageIndex > 0) {
          this.onMovePrevious();
        }
      } },
      { value: $r('app.string.move_page_later'), action: () => {
        if (!this.busy && !this.photoImportLeaseActive &&
          this.currentPageIndex < this.pageCount - 1) {
          this.onMoveNext();
        }
      } },
      { value: $r('app.string.bookmark_page'), action: () => {
        if (this.busy || this.photoImportLeaseActive) {
          return;
        }
        this.onToggleBookmark();
      } },
      { value: $r('app.string.rotate_page'), action: () => {
        if (this.busy || this.photoImportLeaseActive) {
          return;
        }
        this.onRotatePage();
      } },
      { value: $r('app.string.clear_page'), action: () => {
        if (this.busy || this.photoImportLeaseActive) {
          return;
        }
        this.onClearPage();
      } },
      { value: $r('app.string.delete_page'), action: () => {
        if (!this.busy && !this.photoImportLeaseActive &&
          this.pageCount > 1) {
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
      photoImportLeaseActive: this.photoImportLeaseActive,
      popupMode: true,
      onApply: (settings: NoteBackgroundSettings) => {
        this.onApplyNoteBackground(settings);
      },
    })
  }
}

// 原版 ke1/n8：Jump to page 对话框——标题 + 页码输入 + Cancel/Go；
// Go 仅在输入解析为整数且 1<=n<=pageCount 时可用（svd.p0 校验对齐）。
@CustomDialog
struct JumpToPageDialog {
  controller?: CustomDialogController;
  pageCount: number = 1;
  initialValue: string = '';
  @State inputText: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onGo: (pageIndex: number) => void = (_pageIndex: number): void => {
  };

  aboutToAppear(): void {
    this.inputText = this.initialValue;
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // n8 case 21: svd.p0(input) parses; Go enabled iff 1 <= n <= pageCount.
  private targetPage(): number {
    const parsed: number = parseInt(this.inputText.trim(), 10);
    if (isNaN(parsed) || parsed.toString() !== this.inputText.trim()) {
      return -1;
    }
    return parsed;
  }

  private goEnabled(): boolean {
    const target: number = this.targetPage();
    return target >= 1 && target <= this.pageCount;
  }

  build() {
    Column() {
      Text($r('app.string.jump_to_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      TextInput({ text: this.inputText, placeholder: $r('app.string.jump_to_page_label') })
        .width('100%')
        .type(InputType.Number)
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().control)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.inputText = value;
        })
      Row() {
        Button($r('app.string.cancel'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            if (this.controller !== undefined) {
              this.controller.close();
            }
          })
        Button($r('app.string.jump_to_go'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .enabled(this.goEnabled())
          .opacity(this.goEnabled() ? 1 : 0.4)
          .onClick(() => {
            const target: number = this.targetPage();
            if (target < 1 || target > this.pageCount) {
              return;
            }
            this.onGo(target - 1);
            if (this.controller !== undefined) {
              this.controller.close();
            }
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}
