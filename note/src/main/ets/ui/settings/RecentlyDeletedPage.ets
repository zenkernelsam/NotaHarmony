// T-531 最近删除页面：对齐原版 feature_settings__recently_deleted。
// 原版行为（decompiled_1.0.3 leb/x17/e47 + strings.xml）：
// - 资料库删除 -> ClientNoteUpdate DELETE row（软删），Recently Deleted 列出
// - Recover -> 移除 DELETE row（恢复）；Delete -> PermanentlyDeletedNote 墓碑 + 硬删
// - 30 天未恢复的笔记被永久删除
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl, TRASH_RETENTION_MS } from '../../data/NoteRepositoryImpl';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

enum TrashLoadState {
  LOADING = 'loading',
  ERROR = 'error',
  READY = 'ready',
}

const MS_PER_DAY: number = 24 * 60 * 60 * 1000;

@Entry
@Component
struct RecentlyDeletedPage {
  @State loadState: TrashLoadState = TrashLoadState.LOADING;
  @State trashedNotes: NoteMeta[] = [];
  @State busy: boolean = false;

  private db: DatabaseManager = DatabaseManager.getInstance();
  private initialized: boolean = false;
  private loadGeneration: number = 0;
  private lifecycleGeneration: number = 0;
  private pageDisposed: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 必须用普通方法形式，否则 build 中访问 this.resolveTokens().xxx 会抛 TypeError
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.reloadPage();
  }

  aboutToDisappear(): void {
    this.pageDisposed = true;
    this.lifecycleGeneration++;
  }

  onPageShow(): void {
    if (this.initialized) {
      this.reloadPage();
    }
  }

  private async reloadPage(): Promise<void> {
    const expectedLifecycleGeneration: number = this.lifecycleGeneration;
    const generation: number = ++this.loadGeneration;
    this.loadState = TrashLoadState.LOADING;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.db.initialize(context);
      const repo = new NoteRepositoryImpl(this.db);
      // 原版 30 天规则：打开页面即结算过期笔记，无需后台 worker。
      await repo.purgeExpiredTrash(Date.now());
      const loaded: NoteMeta[] = await repo.getTrashedNotes();
      if (this.pageDisposed || generation !== this.loadGeneration ||
        expectedLifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.trashedNotes = loaded;
      this.loadState = TrashLoadState.READY;
      this.initialized = true;
    } catch (e) {
      console.error(`RecentlyDeletedPage load failed: ${JSON.stringify(e)}`);
      if (!this.pageDisposed && generation === this.loadGeneration &&
        expectedLifecycleGeneration === this.lifecycleGeneration) {
        this.loadState = TrashLoadState.ERROR;
      }
    }
  }

  private daysLeft(note: NoteMeta): number {
    if (note.deletedAt === null) {
      return 0;
    }
    const remaining: number = TRASH_RETENTION_MS - (Date.now() - note.deletedAt);
    return Math.max(0, Math.ceil(remaining / MS_PER_DAY));
  }

  private formatDeletedTime(note: NoteMeta): string {
    if (note.deletedAt === null) {
      return '';
    }
    const date: Date = new Date(note.deletedAt);
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private confirmPermanentlyDelete(note: NoteMeta): void {
    if (this.busy) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_permanently'),
      message: $r('app.string.delete_permanently_message', note.title),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: this.resolveTokens().danger,
        action: () => {
          this.permanentlyDelete(note.id).catch((e: Error) => {
            console.error(`permanent delete failed: ${JSON.stringify(e)}`);
          });
        },
      },
    });
  }

  private async recoverNote(noteId: string): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const repo = new NoteRepositoryImpl(this.db);
      await repo.restoreNote(noteId);
      await this.reloadPage();
    } catch (e) {
      console.error(`recover note failed: ${JSON.stringify(e)}`);
      if (!this.pageDisposed) {
        this.showToast($r('app.string.recover_note_failed'));
      }
    } finally {
      this.busy = false;
    }
  }

  private async permanentlyDelete(noteId: string): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const repo = new NoteRepositoryImpl(this.db);
      await repo.deleteNote(noteId);
      await this.reloadPage();
    } catch (e) {
      console.error(`permanent delete failed: ${JSON.stringify(e)}`);
      if (!this.pageDisposed) {
        this.showToast($r('app.string.delete_permanently_failed'));
      }
    } finally {
      this.busy = false;
    }
  }

  private showToast(message: ResourceStr): void {
    try {
      promptAction.showToast({ message: message, duration: 2500 });
    } catch (e) {
      console.error(`showToast failed: ${JSON.stringify(e)}`);
    }
  }

  @Builder
  TrashedNoteRow(note: NoteMeta) {
    Column() {
      Row() {
        Column() {
          Text(note.title.length > 0 ? note.title : $r('app.string.untitled_note'))
            .fontSize(16)
            .fontColor(this.resolveTokens().textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text($r('app.string.recently_deleted_meta',
            this.formatDeletedTime(note), this.daysLeft(note)))
            .fontSize(12)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button($r('app.string.recover_note'))
          .height(36)
          .enabled(!this.busy)
          .onClick(() => {
            this.recoverNote(note.id).catch((e: Error) => {
              console.error(`recover action failed: ${JSON.stringify(e)}`);
            });
          })
        Button($r('app.string.delete'))
          .height(36)
          .fontColor(this.resolveTokens().danger)
          .enabled(!this.busy)
          .margin({ left: 8 })
          .onClick(() => {
            this.confirmPermanentlyDelete(note);
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.resolveTokens().surface)
    .margin({ bottom: 8 })
    .borderRadius(8)
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
        Text($r('app.string.recently_deleted'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 16 })

      if (this.loadState === TrashLoadState.LOADING) {
        Row() {
          LoadingProgress().width(22).height(22)
          Text($r('app.string.settings_loading'))
            .fontSize(14)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ left: 8 })
        }
        .margin({ top: 24 })
      } else if (this.loadState === TrashLoadState.ERROR) {
        Column() {
          Text($r('app.string.recently_deleted_load_failed'))
            .fontSize(14)
            .fontColor(this.resolveTokens().danger)
            .margin({ bottom: 12 })
          Button($r('app.string.retry'))
            .onClick(() => {
              if (this.busy) {
                return;
              }
              this.reloadPage();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24 })
      } else {
        Scroll() {
          Column() {
            Text($r('app.string.recently_deleted_empty_state_header'))
              .width('100%')
              .fontSize(13)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ bottom: 16 })

            if (this.trashedNotes.length === 0) {
              Text($r('app.string.recently_deleted_empty_state_message'))
                .width('100%')
                .fontSize(14)
                .fontColor(this.resolveTokens().textSecondary)
                .margin({ top: 32 })
            } else {
              ForEach(this.trashedNotes, (note: NoteMeta) => {
                this.TrashedNoteRow(note)
              }, (note: NoteMeta) => note.id)
            }
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
