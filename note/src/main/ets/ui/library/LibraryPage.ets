// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { LibraryViewModel } from './LibraryViewModel';

@Entry
@Component
struct LibraryPage {
  // === 响应式状态 ===
  @State columns: number = 3;
  @State sidebarWidth: number = 0;
  @State showSidebar: boolean = false;
  // === 数据状态 ===
  @State viewModel: LibraryViewModel | null = null;
  @State searchText: string = '';
  private noteRepo: NoteRepositoryImpl | null = null;

  aboutToAppear(): void {
    this.initData();
  }

  private navigateToBackup(): void {
    router.pushUrl({ url: 'ui/settings/BackupPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  private async initData(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.noteRepo = new NoteRepositoryImpl(db);
      const vm: LibraryViewModel = new LibraryViewModel(this.noteRepo);
      await vm.loadNotes();
      this.viewModel = vm;
    } catch (e) {
      console.error(`LibraryPage init failed: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Row() {
      // 侧栏（≥840vp 显示）
      if (this.showSidebar) {
        Column() {
          Text('Nota')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16, bottom: 16 })
          Text('Home').fontSize(16).margin({ top: 8, bottom: 8 })
          Text('Notes').fontSize(16).margin({ top: 8, bottom: 8 })
          Text('Folders').fontSize(16).margin({ top: 8, bottom: 8 })
        }
        .width(this.sidebarWidth)
        .height('100%')
        .backgroundColor(Color.Gray)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16 })
      }

      // 主内容
      Column() {
        // 搜索栏（48vp）+ 设置入口
        Row() {
          TextInput({ placeholder: 'Search notes' })
            .layoutWeight(1)
            .height(40)
            .onChange((value: string) => {
              this.searchText = value;
              if (this.viewModel !== null) {
                this.viewModel.searchQuery = value;
              }
            })
          Button('设置')
            .height(40)
            .margin({ left: 8 })
            .onClick(() => {
              this.navigateToBackup();
            })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })

        // 笔记网格
        if (this.viewModel !== null) {
          Grid() {
            ForEach(this.viewModel.getFilteredNotes(), (note: NoteMeta) => {
              GridItem() {
                this.NoteCard(note)
              }
            }, (note: NoteMeta) => note.id)
          }
          .columnsTemplate('1fr '.repeat(this.columns))
          .columnsGap(16)
          .rowsGap(16)
          .padding(16)
          .layoutWeight(1)
        } else {
          Text('Loading...').fontSize(16).layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const widthVp: number = newArea.width as number;
      this.applyBreakpoints(widthVp);
    })
    .overlay(this.FabButton(), { align: Alignment.BottomEnd })
  }

  // FAB 新建按钮（64vp 右下角）
  @Builder
  FabButton() {
    Button('+')
      .width(64)
      .height(64)
      .fontSize(28)
      .borderRadius(32)
      .margin({ right: 24, bottom: 24 })
      .onClick(() => {
        this.createAndOpen();
      })
  }

  @Builder
  NoteCard(note: NoteMeta) {
    Column() {
      // 缩略图占位（灰色矩形）
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#E0E0E0')
        .borderRadius(8)
      Text(note.title)
        .fontSize(14)
        .maxLines(1)
        .margin({ top: 8 })
      Text(this.formatTime(note.updatedAt))
        .fontSize(12)
        .fontColor('#888888')
        .margin({ top: 2 })
    }
    .width('100%')
    .height(180)
    .padding(8)
    .borderRadius(12)
    .backgroundColor(Color.White)
    .shadow({ radius: 4, color: '#22000000', offsetY: 2 })
    .onClick(() => {
      router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: note.id } })
        .catch((err: BusinessError) => {
          console.error(`pushUrl failed: ${err.code}`);
        });
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.confirmDelete(note);
        })
    )
  }

  private confirmDelete(note: NoteMeta): void {
    // T-033：原生 AlertDialog（getUIContext 新 API，替代弃用的 AlertDialog.show）
    this.getUIContext().showAlertDialog({
      title: 'Delete Note',
      message: 'Delete "' + note.title + '"? This cannot be undone.',
      primaryButton: {
        value: 'Cancel',
        action: () => {
        },
      },
      secondaryButton: {
        value: 'Delete',
        fontColor: '#E84026',
        action: () => {
          if (this.viewModel !== null) {
            this.viewModel.deleteNote(note.id);
          }
        },
      },
    });
  }

  private async createAndOpen(): Promise<void> {
    if (this.viewModel === null) {
      return;
    }
    const noteId: string = await this.viewModel.createNote();
    router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: noteId } })
      .catch((err: BusinessError) => {
        console.error(`pushUrl failed: ${err.code}`);
      });
  }

  // 响应式断点（§39.4：600/840/952/1400vp）
  private applyBreakpoints(widthVp: number): void {
    if (widthVp >= 1400) {
      this.columns = 4;
      this.sidebarWidth = 332;
      this.showSidebar = true;
    } else if (widthVp >= 952) {
      this.columns = 3;
      this.sidebarWidth = 332;
      this.showSidebar = true;
    } else if (widthVp >= 840) {
      this.columns = 2;
      this.sidebarWidth = 280;
      this.showSidebar = true;
    } else {
      this.columns = widthVp >= 600 ? 3 : 2;
      this.sidebarWidth = 0;
      this.showSidebar = false;
    }
  }

  private formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp);
    return d.getMonth() + 1 + '/' + d.getDate() + ' ' + d.getHours() + ':' +
      (d.getMinutes() < 10 ? '0' : '') + d.getMinutes();
  }
}
