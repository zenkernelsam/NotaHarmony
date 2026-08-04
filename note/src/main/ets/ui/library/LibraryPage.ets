// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { FolderRepositoryImpl, NoteFolder } from '../../data/FolderRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import { LibraryViewModel, NoteSortMode } from './LibraryViewModel';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

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
  // T-035：缩略图——@State 数组驱动 UI 刷新（Builder 中 Map 方法依赖收集不可靠）
  @State thumbIds: string[] = [];
  private thumbMap: Map<string, PixelMap> = new Map<string, PixelMap>();
  private noteRepo: NoteRepositoryImpl | null = null;
  // T-039：文件夹
  private folderRepo: FolderRepositoryImpl | null = null;
  @State folders: NoteFolder[] = [];
  @State currentFolderId: string | null = null;
  @State folderDialogTitle: string = '新建文件夹';
  @State folderDialogMode: number = 0;  // 0=新建 1=重命名
  @State folderDialogTargetId: string = '';
  private folderDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: this.folderDialogTitle,
      initialText: '',
      onConfirm: (name: string) => {
        this.onFolderDialogConfirm(name);
      },
    }),
    autoCancel: true,
  });
  private persistence: StrokePersistence = new StrokePersistence();
  private thumbRenderer: ThumbnailRenderer = new ThumbnailRenderer();
  private db: DatabaseManager = DatabaseManager.getInstance();
  private readonly PREF_SORT_KEY: string = 'library_sort_mode';
  private readonly PREF_THEME_KEY: string = 'theme_mode';
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private get tokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.initData();
  }

  private navigateToBackup(): void {
    router.pushUrl({ url: 'ui/settings/BackupPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  // T-035：异步渲染全部缩略图（空笔记跳过）
  private async refreshThumbnails(): Promise<void> {
    if (this.viewModel === null) {
      return;
    }
    const newMap: Map<string, PixelMap> = new Map<string, PixelMap>();
    for (const note of this.viewModel.notes) {
      const pm: PixelMap | null = await this.thumbRenderer.renderThumbnail(note.id,
        this.persistence);
      if (pm !== null) {
        newMap.set(note.id, pm);
      }
    }
    this.thumbMap = newMap;
    this.thumbIds = Array.from(newMap.keys());
    console.info(`LibraryPage: thumbs refreshed size=${newMap.size}`);
  }

  // T-039：文件夹操作
  private showCreateFolderDialog(): void {
    this.folderDialogMode = 0;
    this.folderDialogTitle = '新建文件夹';
    this.folderDialogTargetId = '';
    this.folderDialog = new CustomDialogController({
      builder: NameDialog({
        title: this.folderDialogTitle,
        initialText: '',
        onConfirm: (name: string) => {
          this.onFolderDialogConfirm(name);
        },
      }),
      autoCancel: true,
    });
    this.folderDialog.open();
  }

  private showRenameFolderDialog(folder: NoteFolder): void {
    this.folderDialogMode = 1;
    this.folderDialogTitle = '重命名文件夹';
    this.folderDialogTargetId = folder.id;
    this.folderDialog = new CustomDialogController({
      builder: NameDialog({
        title: this.folderDialogTitle,
        initialText: folder.name,
        onConfirm: (name: string) => {
          this.onFolderDialogConfirm(name);
        },
      }),
      autoCancel: true,
    });
    this.folderDialog.open();
  }

  private async onFolderDialogConfirm(name: string): Promise<void> {
    const trimmed: string = name.trim();
    if (trimmed.length === 0 || this.folderRepo === null) {
      return;
    }
    if (this.folderDialogMode === 0) {
      await this.folderRepo.createFolder(trimmed);
    } else if (this.folderDialogMode === 1) {
      await this.folderRepo.renameFolder(this.folderDialogTargetId, trimmed);
    }
    this.folders = await this.folderRepo.getAllFolders();
  }

  // 删除文件夹：内部笔记回根目录（不删笔记）
  private async deleteFolder(folderId: string): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null) {
      return;
    }
    const notes: NoteMeta[] = this.viewModel.getFilteredNotes();
    for (const n of notes) {
      if (n.folderId === folderId) {
        await this.folderRepo.moveNoteToFolder(n.id, null);
      }
    }
    await this.folderRepo.deleteFolder(folderId);
    this.folders = await this.folderRepo.getAllFolders();
    if (this.currentFolderId === folderId) {
      this.currentFolderId = null;
      this.viewModel.setFolder(null);
    }
    this.refreshThumbnails();
  }

  // 移动笔记到文件夹（null=根目录）
  private async moveNote(noteId: string, folderId: string | null): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null) {
      return;
    }
    await this.folderRepo.moveNoteToFolder(noteId, folderId);
    await this.viewModel.loadNotes();
  }

  // 切换浏览文件夹
  private selectFolder(folderId: string | null): void {
    if (this.viewModel === null) {
      return;
    }
    this.currentFolderId = folderId;
    this.viewModel.setFolder(folderId);
    this.refreshThumbnails();
  }

  // T-035：排序切换 + Preferences 持久化
  private setSortMode(mode: NoteSortMode): void {
    if (this.viewModel === null) {
      return;
    }
    this.viewModel.setSortMode(mode);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, 'library_prefs').then((pref: preferences.Preferences) => {
        pref.putSync(this.PREF_SORT_KEY, mode);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save sort pref flush failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save sort pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`setSortMode failed: ${JSON.stringify(e)}`);
    }
  }

  private async initData(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      ThemeStore.init();
      // T-038：恢复主题偏好 + 检测系统色模式
      const themePref = await preferences.getPreferences(context, 'library_prefs');
      const savedTheme: string = themePref.getSync(this.PREF_THEME_KEY, 'system') as string;
      ThemeStore.setMode(savedTheme as ThemeMode);
      this.detectSystemDark(context);
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
      this.noteRepo = new NoteRepositoryImpl(this.db);
      this.folderRepo = new FolderRepositoryImpl(this.db);
      this.folders = await this.folderRepo.getAllFolders();
      const vm: LibraryViewModel = new LibraryViewModel(this.noteRepo);
      // 恢复排序偏好
      const pref = await preferences.getPreferences(context, 'library_prefs');
      const saved: number = pref.getSync(this.PREF_SORT_KEY, 0) as number;
      vm.sortMode = saved as NoteSortMode;
      await vm.loadNotes();
      this.viewModel = vm;
      this.refreshThumbnails();
    } catch (e) {
      console.error(`LibraryPage init failed: ${JSON.stringify(e)}`);
    }
  }

  // T-038：系统色模式检测（ConfigurationConstant.ColorMode）
  private detectSystemDark(context: common.UIAbilityContext): void {
    try {
      const config = context.config;
      ThemeStore.setSystemDark(config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } catch (e) {
      ThemeStore.setSystemDark(false);
    }
  }

  // T-038：系统颜色变化监听（@Entry 生命周期；ArkUI Configuration.colorMode 为字符串）
  onConfigurationUpdate(config: Configuration): void {
    ThemeStore.setSystemDark(config.colorMode === 'dark');
  }

  // T-038：主题切换 + 持久化
  private setThemeMode(mode: ThemeMode): void {
    ThemeStore.setMode(mode);
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, 'library_prefs').then((pref: preferences.Preferences) => {
        pref.putSync(this.PREF_THEME_KEY, mode);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save theme pref failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save theme pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`setThemeMode failed: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Row() {
      // 侧栏（≥840vp 显示；T-039 文件夹列表）
      if (this.showSidebar) {
        Column() {
          Text('Nota')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tokens.textPrimary)
            .margin({ top: 16, bottom: 12 })
          // 全部笔记
          Text('全部笔记')
            .fontSize(15)
            .fontColor(this.currentFolderId === null ? this.tokens.accent : this.tokens.textPrimary)
            .fontWeight(this.currentFolderId === null ? FontWeight.Medium : FontWeight.Normal)
            .margin({ top: 4, bottom: 4 })
            .onClick(() => {
              this.selectFolder(null);
            })
          // 文件夹列表
          ForEach(this.folders, (folder: NoteFolder) => {
            Text(folder.name)
              .fontSize(15)
              .fontColor(this.currentFolderId === folder.id ? this.tokens.accent : this.tokens.textPrimary)
              .fontWeight(this.currentFolderId === folder.id ? FontWeight.Medium : FontWeight.Normal)
              .margin({ top: 4, bottom: 4 })
              .onClick(() => {
                this.selectFolder(folder.id);
              })
              .gesture(
                LongPressGesture()
                  .onAction(() => {
                    this.getUIContext().showAlertDialog({
                      title: folder.name,
                      message: '',
                      primaryButton: {
                        value: '重命名',
                        action: () => {
                          this.showRenameFolderDialog(folder);
                        },
                      },
                      secondaryButton: {
                        value: '删除',
                        fontColor: '#E84026',
                        action: () => {
                          this.deleteFolder(folder.id);
                        },
                      },
                    });
                  })
              )
          }, (folder: NoteFolder) => folder.id)
          Blank()
          // 新建文件夹
          Button('+ 新建文件夹')
            .height(36)
            .fontSize(13)
            .margin({ bottom: 16 })
            .onClick(() => {
              this.showCreateFolderDialog();
            })
        }
        .width(this.sidebarWidth)
        .height('100%')
        .backgroundColor(this.tokens.surface)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 8 })
      }

      // 主内容
      Column() {
        // T-039：当前文件夹名（非全部时显示 + 返回入口）
        if (this.currentFolderId !== null) {
          Row() {
            Text('文件夹：' + this.currentFolderName())
              .fontSize(14)
              .fontColor(this.tokens.accent)
              .onClick(() => {
                this.selectFolder(null);
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8 })
        }
        // 搜索栏（48vp）+ 设置入口 + 排序
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
          Button('排序')
            .height(40)
            .fontSize(13)
            .margin({ left: 8 })
            .bindMenu([
              { value: '最近修改', action: () => { this.setSortMode(NoteSortMode.UPDATED); } },
              { value: '最近创建', action: () => { this.setSortMode(NoteSortMode.CREATED); } },
              { value: '标题', action: () => { this.setSortMode(NoteSortMode.TITLE); } },
            ])
          // T-038：主题切换入口
          Button('主题')
            .height(40)
            .fontSize(13)
            .margin({ left: 8 })
            .bindMenu([
              { value: '跟随系统', action: () => { this.setThemeMode('system'); } },
              { value: '浅色', action: () => { this.setThemeMode('light'); } },
              { value: '深色', action: () => { this.setThemeMode('dark'); } },
            ])
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
          if (this.viewModel.getFilteredNotes().length === 0) {
            // 空结果提示（T-035）
            Column() {
              Text('无匹配笔记')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
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
          }
        } else {
          Text('Loading...').fontSize(16).layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.tokens.background)
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
      // 缩略图（T-035：@State thumbIds 驱动；无缩略图时灰色占位）
      if (this.thumbIds.indexOf(note.id) >= 0) {
        Image(this.thumbMap.get(note.id))
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      } else {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#E0E0E0')
          .borderRadius(8)
      }
      Text(note.title)
        .fontSize(14)
        .maxLines(1)
        .fontColor(this.tokens.textPrimary)
        .margin({ top: 8 })
      Text(this.formatTime(note.updatedAt))
        .fontSize(12)
        .fontColor(this.tokens.textSecondary)
        .margin({ top: 2 })
    }
    .width('100%')
    .height(180)
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.tokens.surface)
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
          // T-039：长按弹出原生 bindMenu（删除/移动到文件夹）
        })
    )
    .bindMenu(this.buildNoteMenu(note))
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
            // T-035：删除后刷新缩略图缓存
            this.thumbRenderer.clearCache();
            this.refreshThumbnails();
          }
        },
      },
    });
  }

  // 构建笔记长按菜单（T-039：删除 + 移动到文件夹动态列表）
  private buildNoteMenu(note: NoteMeta): MenuElement[] {
    const items: MenuElement[] = [
      { value: '删除', action: () => { this.confirmDelete(note); } },
      { value: '移动到根目录', action: () => { this.moveNote(note.id, null); } },
    ];
    for (const f of this.folders) {
      items.push({
        value: '移动到「' + f.name + '」',
        action: () => { this.moveNote(note.id, f.id); },
      });
    }
    return items;
  }

  // 当前文件夹名（顶部显示）
  private currentFolderName(): string {
    for (const f of this.folders) {
      if (f.id === this.currentFolderId) {
        return f.name;
      }
    }
    return '全部笔记';
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

// T-039：名称输入对话框（@CustomDialog 原生）
@CustomDialog
struct NameDialog {
  controller?: CustomDialogController;
  title: string = '';
  initialText: string = '';
  @State inputText: string = '';
  onConfirm: (name: string) => void = () => {
  };

  aboutToAppear(): void {
    this.inputText = this.initialText;
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      TextInput({ text: this.inputText, placeholder: '名称' })
        .width('100%')
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.inputText = value;
        })
      Row() {
        Button('取消')
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            if (this.controller !== undefined) {
              this.controller.close();
            }
          })
        Button('确定')
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm(this.inputText);
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
  }
}
