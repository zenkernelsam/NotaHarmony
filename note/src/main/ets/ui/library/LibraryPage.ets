// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
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
            // T-035：删除后刷新缩略图缓存
            this.thumbRenderer.clearCache();
            this.refreshThumbnails();
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
