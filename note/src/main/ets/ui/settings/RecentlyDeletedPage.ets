// T-531 最近删除页面：对齐原版 feature_settings__recently_deleted。
// 原版行为（decompiled_1.0.3 leb/x17/e47 + strings.xml）：
// - 资料库删除 -> ClientNoteUpdate DELETE row（软删），Recently Deleted 列出
// - Recover -> 移除 DELETE row（恢复）；Delete -> PermanentlyDeletedNote 墓碑 + 硬删
// - 30 天未恢复的笔记被永久删除
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';

enum TrashLoadState {
  LOADING = 'loading',
  ERROR = 'error',
  READY = 'ready',
}

@Entry
@Component
struct RecentlyDeletedPage {
  @State loadState: TrashLoadState = TrashLoadState.LOADING;
  @State trashedNotes: NoteMeta[] = [];
  @State selectedTrashIds: string[] = [];
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
      // 原版 p6e/invokeSuspend：选集与列表来自同一状态流；列表重建后
      // 丢弃已不在回收站中的 id（30 天结算或批量操作后可缺）。
      const stillPresent: Set<string> = new Set(loaded.map((n: NoteMeta) => n.id));
      this.selectedTrashIds = this.selectedTrashIds.filter((id: string) => stillPresent.has(id));
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

  // Original bib/nhb row subtitle: feature_settings__note_deleted_at
  // ("Deleted %1$s") filled with z5c.n = ofLocalizedDate(MEDIUM).
  private formatDeletedTime(note: NoteMeta): string {
    if (note.deletedAt === null) {
      return '';
    }
    try {
      return new Intl.DateTimeFormat(undefined,
        { dateStyle: 'medium' }).format(new Date(note.deletedAt));
    } catch (_error) {
      const d: Date = new Date(note.deletedAt);
      return d.getMonth() + 1 + '/' + d.getDate() + '/' + d.getFullYear();
    }
  }

  // 原版 wrl.h/fq9.p + oe(24)->g6e(bpj)：整行点击与复选框共用同一
  // 选择切换 UserAction，各自只触发一次切换。
  private toggleNoteSelection(noteId: string): void {
    if (this.busy) {
      return;
    }
    if (this.selectedTrashIds.includes(noteId)) {
      this.selectedTrashIds = this.selectedTrashIds.filter((id: string) => id !== noteId);
    } else {
      this.selectedTrashIds = [...this.selectedTrashIds, noteId];
    }
  }

  // 原版 wrl.i 顶部行：a6e.a = Select all / Deselect all（p6e 以
  // zx7.r(set, map.keySet()) 判定全选态），onClick -> w5e(5) -> j6e。
  private toggleSelectAll(): void {
    if (this.busy) {
      return;
    }
    if (this.selectedTrashIds.length === this.trashedNotes.length) {
      this.selectedTrashIds = [];
    } else {
      this.selectedTrashIds = this.trashedNotes.map((n: NoteMeta) => n.id);
    }
  }

  // 原版 wrl.b -> l8n.c：正文 = a6e.e =
  // feature_settings__delete_confirmation_message 复数条（p6e 以
  // set.size() 选 one/other）；确认钮 "Delete"
  // （feature_settings__delete_notes，w5e(1) 确认动作），取消钮
  // "Keep notes"（feature_settings__keep_notes，w5e(0) 关闭）。
  // 原版无标题位（iqm 调用点可证 str 槽位是确认钮文案）。
  private confirmDeleteSelected(): void {
    if (this.busy || this.selectedTrashIds.length === 0) {
      return;
    }
    const count: number = this.selectedTrashIds.length;
    this.getUIContext().showAlertDialog({
      message: $r(count === 1 ?
        'app.string.feature_settings__delete_confirmation_message_one' :
        'app.string.feature_settings__delete_confirmation_message_other',
        count),
      primaryButton: {
        value: $r('app.string.feature_settings__keep_notes'),
        action: () => {
        },
      },
      secondaryButton: {
        value: $r('app.string.feature_settings__delete_notes'),
        fontColor: this.resolveTokens().danger,
        action: () => {
          this.permanentlyDeleteSelected().catch((e: Error) => {
            console.error(`permanent delete failed: ${JSON.stringify(e)}`);
          });
        },
      },
    });
  }

  // 原版 v5e case0 -> w5e(3)：Recover notes 批量动作（a6e.d =
  // 选集非空时才可用）。原版 note_limit_recover_* 上限挽留
  // （wrl.f -> l8n.e）属付费墙流程，Harmony 免费模型下 fail-closed。
  private async recoverSelected(): Promise<void> {
    if (this.busy || this.selectedTrashIds.length === 0) {
      return;
    }
    this.busy = true;
    try {
      const repo = new NoteRepositoryImpl(this.db);
      for (const id of this.selectedTrashIds) {
        await repo.restoreNote(id);
      }
      this.selectedTrashIds = [];
      await this.reloadPage();
    } catch (e) {
      console.error(`recover notes failed: ${JSON.stringify(e)}`);
      if (!this.pageDisposed) {
        this.showToast($r('app.string.recover_note_failed'));
      }
    } finally {
      this.busy = false;
    }
  }

  // 原版 v5e case0 -> w5e(2) 弹确认 -> w5e(1)：Delete 批量动作，
  // 同样以 a6e.d 门控。
  private async permanentlyDeleteSelected(): Promise<void> {
    if (this.busy || this.selectedTrashIds.length === 0) {
      return;
    }
    this.busy = true;
    try {
      const repo = new NoteRepositoryImpl(this.db);
      for (const id of this.selectedTrashIds) {
        await repo.deleteNote(id);
      }
      this.selectedTrashIds = [];
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

  // 原版 z5e 标题字段：ycb.getTitle() 为空时落到
  // data_library_state__default_note_title（与 e5j.h 物化规则一致）。
  private noteDisplayTitle(note: NoteMeta): string {
    if (note.title.length > 0) {
      return note.title;
    }
    try {
      return getContext(this).resourceManager.getStringSync($r('app.string.untitled_note').id);
    } catch (_e) {
      return 'New Note';
    }
  }

  // 原版 wrl.h -> x8n.a：标题/"Deleted %s" 副文列 + 尾随 mo2(7) =
  // f9n.b 复选框（选中态决定 cd_select/cd_deselect_note_titled），
  // 整行 fq9.p 可点击 = oe(24) -> g6e(bpj) 选择切换；原版行内没有
  // Recover/Delete 单条按钮，批量动作集中在底部条（v5e case0）。
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
            this.formatDeletedTime(note)))
            .fontSize(12)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 原版 mo2(7)=f9n.b 复选框语义（select/deselect_note_titled）
        // 与整行 fq9.p 点击共用同一个 g6e 切换动作；这里令复选框只做
        // 语义+视觉呈现（hitTestBehavior None），触摸统一走行 onClick，
        // 避免一次点击被行+框各消费一遍造成双重切换。
        Checkbox()
          .select(this.selectedTrashIds.includes(note.id))
          .accessibilityText(this.selectedTrashIds.includes(note.id) ?
            $r('app.string.cd_deselect_note_titled', this.noteDisplayTitle(note)) :
            $r('app.string.cd_select_note_titled', this.noteDisplayTitle(note)))
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.resolveTokens().surface)
    .margin({ bottom: 8 })
    .borderRadius(8)
    .onClick(() => {
      this.toggleNoteSelection(note.id);
    })
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
              // 原版 wrl.i 首项：o9n.a 文本按钮行，文案 = a6e.a =
              // Select all（选集==全集时换 Deselect all，p6e 的
              // zx7.r(set, map.keySet())），onClick -> w5e(5) = j6e
              // 全选切换。
              Text(this.selectedTrashIds.length === this.trashedNotes.length ?
                $r('app.string.feature_settings__deselect_all') :
                $r('app.string.select_all'))
                .fontSize(15)
                .fontColor(this.resolveTokens().accent)
                .padding({ top: 10, bottom: 10 })
                .accessibilityText(this.selectedTrashIds.length ===
                  this.trashedNotes.length ?
                  $r('app.string.feature_settings__deselect_all') :
                  $r('app.string.select_all'))
                .onClick(() => {
                  this.toggleSelectAll();
                })

              // 原版 wrl.i 次项：x7n.e(a6e.b != null) = "N notes
              // selected" 横幅（feature_settings__notes_selected
              // 复数条，p6e 以 set.size() 选 one/other），仅选集
              // 非空时出现。
              if (this.selectedTrashIds.length > 0) {
                Text($r(this.selectedTrashIds.length === 1 ?
                  'app.string.feature_settings__notes_selected_one' :
                  'app.string.feature_settings__notes_selected_other',
                  this.selectedTrashIds.length))
                  .width('100%')
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textSecondary)
                  .margin({ bottom: 8 })
              }

              ForEach(this.trashedNotes, (note: NoteMeta) => {
                this.TrashedNoteRow(note)
              }, (note: NoteMeta) => note.id)
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })
        }
        .layoutWeight(1)

        // 原版 v5e case0 底部动作条（wrl.g -> x7n.e(!a6e.g) 列表非空
        // 才显示）：Delete（mma.G 危险色）在左、Recover notes
        // （primary）在右，两者均以 a6e.d = 选集非空 门控。
        if (this.loadState === TrashLoadState.READY &&
          this.trashedNotes.length > 0) {
          Row() {
            Button($r('app.string.feature_settings__delete_notes'))
              .layoutWeight(1)
              .height(40)
              .fontColor(this.resolveTokens().danger)
              .enabled(this.selectedTrashIds.length > 0 && !this.busy)
              .onClick(() => {
                this.confirmDeleteSelected();
              })
            Button($r('app.string.feature_settings__recover_notes'))
              .layoutWeight(1)
              .height(40)
              .margin({ left: 8 })
              .enabled(this.selectedTrashIds.length > 0 && !this.busy)
              .onClick(() => {
                this.recoverSelected().catch((e: Error) => {
                  console.error(`recover action failed: ${JSON.stringify(e)}`);
                });
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 8, bottom: 12 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }
}
