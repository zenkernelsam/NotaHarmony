// T-019 编辑器工具栏（工具切换 + 颜色/粗细面板 + Undo/Redo 占位）
// T-038：工具栏 surface 随主题
import { BrushStyle, ToolState, ToolType } from '../../core/model/BrushTypes';
import { PageInfo } from '../../core/model/NoteTypes';
import { EditorViewModel } from './EditorViewModel';
import { ToolboxSettingsDialog, toolTypeLabel } from './ToolboxSettingsDialog';
import { ColorPickerView } from '../components/ColorPicker';
import { WidthSlider } from '../components/WidthSlider';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { common } from '@kit.AbilityKit';
import { OnboardingTipBubble } from '../components/OnboardingTipBubble';
import {
  OnboardingTooltipKind, OnboardingTooltipStore,
} from '../../data/OnboardingTooltipStore';

interface PopupStateChangeEvent {
  isVisible: boolean;
}

@Component
export struct EditorToolbar {
  @ObjectLink viewModel: EditorViewModel;
  @State compact: boolean = false;
  @State showToolSettings: boolean = false;
  @State showShareSheet: boolean = false;
  // 原版 v6d.l 页选择集合（Set<Integer>，null=全部页）：非 null 即
  // 显式子集；b7d.q(i,z) 的 toggle 语义由 toggleSharePage 承载。
  @State sharePageIndexes: number[] | null = null;
  // 原版 r6d 面板屏态机：MAIN（格式行 + 页范围行）/ PAGE_SELECTION
  // （缩略图栅格勾选屏，b7d.l 缩略图窗口由 NotePage 侧渲染链承载）。
  @State shareScreen: string = 'main';
  // 原版 v6d.k：null=密码关；非空字符串=已设 PDF 打开密码（主屏
  // zy7 case17 显 On）。PASSWORD_ENTRY 屏的草稿/确认/不一致态。
  @State sharePassword: string | null = null;
  @State sharePasswordDraft: string = '';
  @State sharePasswordConfirm: string = '';
  @State sharePasswordMismatch: boolean = false;
  // 原版 pq9/hq9 引导气泡链（onboardingTooltipSeen Set<String>）：
  // 每条仅在未见过且站点上下文成立时显示；"Got it" 写入 seen 集。
  @State onboardingSeen: string[] = [];
  @State showTipNewNote: boolean = false;
  @State showTipTray: boolean = false;
  @State showTipTool: boolean = false;
  @State showTipUndoRedo: boolean = false;
  @State showTipImport: boolean = false;
  private onboardingStore: OnboardingTooltipStore | null = null;
  private onboardingSeenReady: boolean = false;
  private onboardingTipToolId: string = '';
  private onboardingTipToolKind: OnboardingTooltipKind = OnboardingTooltipKind.FIRST_TEXT;
  private onboardingTipToolText: Resource =
    $r('app.string.data_onboarding__first_text_tooltip_text');
  // 原版 v6d.c 当前选中格式（s6d 枚举 ordinal：link/pdf/note/jpg/
  // png）；原版单笔记默认 LINK、多笔记默认 PDF——LINK 在本端
  // fail-closed（账号后端缺位），默认改取 pdf（文档化适配）。
  @State shareFormat: string = 'pdf';
  // 原版 v6d.i=includeBackground（初值 false）、v6d.j=
  // includeRecording（初值 true）——b7d 构造器初值逐位对齐。
  @State shareIncludeBackground: boolean = false;
  @State shareIncludeRecording: boolean = true;
  private toolbarScroller: Scroller = new Scroller();
  // Undo/Redo 回调（T-021 实现功能）
  onUndo: () => void = () => {
  };
  onRedo: () => void = () => {
  };
  onAddFiles: () => void = () => {
  };
  onInsertMath: () => void = () => {
  };
  onInsertPhotos: () => void = () => {
  };
  onTakePhoto: () => void = () => {
  };
  onSelectionStyle: (style: BrushStyle) => void = (_style: BrushStyle): void => {
  };
  onSelectionColor: (color: number) => void = (_color: number): void => {
  };
  onSelectionWidth: (width: number) => void = (_width: number): void => {
  };
  // 原版 feature_note__toprighttoolbar_share_action → ui_share__chip_note：
  // 分享面板中唯一可由本端管线产出的格式为 .note 包。
  // includeRecording 对应 v6d.j（zk9.a->yk9.O 旗标）。
  onShareNote: (includeRecording: boolean) => void =
    (_includeRecording: boolean): void => {
  };
  // 原版 s6d.JPG/PNG（atc case6/7）：页栅格化导出图像。
  // format 取值 'jpg' | 'png'；pageIndexes=null 时整册打包为单个 zip。
  // includeBackground 对应 v6d.i（JPG/PNG 与 PDF 共用同一开关）。
  onShareImage: (format: string, pageIndexes: number[] | null,
    includeBackground: boolean) => void =
    (_format: string, _pageIndexes: number[] | null,
      _includeBackground: boolean): void => {
  };
  // 原版 s6d.PDF（atc case4）：所选页逐页栅格化导出单个 PDF；
  // pageIndexes=null 表示全部页（v6d.l 空集语义）；password 对应
  // v6d.k——非空时对产物施加打开密码（r6d.PASSWORD_ENTRY 设入）。
  onSharePdf: (pageIndexes: number[] | null, password: string | null,
    includeBackground: boolean) => void =
    (_pageIndexes: number[] | null, _password: string | null,
      _includeBackground: boolean): void => {
  };
  // 分享页选择栅格的页列表与缩略图请求（宿主 NotePage 注入：
  // b7d.l(i,i2) 缩略图窗口的等价物）。普通字段——面板开启时按当前
  // 快照读取，无需深拷贝驱动刷新。
  sharePages: PageInfo[] = [];
  onShareThumb: (page: PageInfo) => Promise<PixelMap | null> =
    (_page: PageInfo): Promise<PixelMap | null> => Promise.resolve(null);
  // 原版 gs8 case2（x90.g 首项）：content-manager 页面面板开关。
  onTogglePagesPanel: () => void = () => {
  };
  @Prop selectionColor: number = -16777216;
  @Prop selectionWidth: number = 5;
  @Prop selectionWidthMinimum: number = 0.5;
  @Prop selectionWidthMaximum: number = 30;
  @Prop photoImportLeaseActive: boolean = false;
  @Prop selectionVariableStyleEnabled: boolean = true;
  @Prop selectionStyle: BrushStyle = BrushStyle.MONO;
  @Prop @Watch('onCanUndoTip') canUndo: boolean = false;
  @Prop canRedo: boolean = false;
  // 原版 x90 z7（pq9.N 站点条件）：任一页存在内容 → 页面管理器气泡。
  @Prop @Watch('onNoteHasContentTip') noteHasContent: boolean = false;
  // 原版 o94 case14：胶带工具设置行内 Hide/Reveal Tapes（NotePage 会话态）。
  @Prop tapeCount: number = 0;
  @Prop anyTapeRevealed: boolean = false;
  onTapeToggle: () => void = () => {
  };
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Scroll(this.toolbarScroller) {
        Row() {
        // 原版 x90.g 顶栏首项（pq9.N → fh2 → gs8 case2）：content-manager
        // 页面面板开关，位于 undo/redo 与工具簇之前。
        Button('▦')
          .width(44)
          .height(32)
          .fontSize(15)
          .margin({ left: 2, right: 4 })
          .enabled(!this.photoImportLeaseActive)
          .accessibilityText($r('app.string.cd_pages_panel_toggle'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.onTogglePagesPanel();
          })
          // 原版 x90 fsi.h(pq9.N, pos3)：页面管理器引导气泡锚定此开关。
          .bindPopup(this.showTipImport, {
            builder: (): void => {
              this.OnboardingImportTip()
            },
            placement: Placement.Left,
            mask: false,
            autoCancel: false,
            onStateChange: (event: PopupStateChangeEvent) => {
              this.showTipImport = event.isVisible;
            },
          })
        // === 工具按钮（48vp 点击区）：按原版托盘顺序渲染可见工具 ===
        ForEach(this.viewModel.visibleToolStates(), (state: ToolState) => {
          if (state.toolType === ToolType.WHOLE_ERASER) {
            if (this.compact) {
              this.StateToolButton($r('app.string.eraser'), state)
            } else {
              this.EraserToolButtons(state)
            }
          } else {
            this.StateToolButton(toolTypeLabel(state.toolType), state)
          }
        }, (state: ToolState): string => state.toolId)
          if (this.compact) {
            Button('...')
              .height(40)
              .fontSize(13)
              .margin({ left: 2, right: 2 })
              .enabled(!this.viewModel.toolStateLoading &&
                !this.photoImportLeaseActive)
              // 原版 feature_note__toolbar_more_menu：溢出菜单描述为
              // "More options"。
              .accessibilityText($r('app.string.toolbar_more_menu'))
              .bindMenu(this.buildCompactToolMenu())
          }
          // 原版 toolbox settings 入口（o6f 工具设置页）
          Button('⚙')
            .height(40)
            .fontSize(15)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .accessibilityText($r('app.string.toolbox_settings'))
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.showToolSettings = true;
            })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // 颜色按钮（当前色圆点）
        Button()
          .width(32)
          .height(32)
          .borderRadius(16)
          // 原版 feature_note__cd_quick_tool_color：色板按钮描述为 "Color"。
          .accessibilityText($r('app.string.cd_quick_tool_color'))
          .backgroundColor(this.viewModel.colorToHex(this.viewModel.isSelectionActive() ?
            this.selectionColor : this.viewModel.brushColor))
          .margin({ left: 4, right: 4 })
          .enabled((this.viewModel.supportsColorControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading &&
            !this.photoImportLeaseActive)
          .opacity((this.viewModel.supportsColorControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.showColorPicker = !this.viewModel.showColorPicker;
            this.viewModel.showWidthSlider = false;
            if (!this.viewModel.showColorPicker) {
              // 面板关闭即 lu7 失效（ADR-0646）。
              this.viewModel.setEyedropperActive(false);
            }
            // 原版 ipi/ys2：FIRST_TRAY_OPENED 前置为 NEW_NOTE 已见。
            if (this.viewModel.showColorPicker &&
              !this.tipSeen(OnboardingTooltipKind.FIRST_TRAY_OPENED) &&
              this.tipSeen(OnboardingTooltipKind.NEW_NOTE)) {
              this.showTipTray = true;
            }
          })
          // 原版 rh8 e5f→pq9.I / ipi→pq9.J：样式选项按钮承载两条气泡。
          .bindPopup(this.showTipNewNote || this.showTipTray, {
            builder: (): void => {
              this.OnboardingAnchorTip()
            },
            placement: Placement.Bottom,
            mask: false,
            autoCancel: false,
            onStateChange: (event: PopupStateChangeEvent) => {
              if (!event.isVisible) {
                this.showTipNewNote = false;
                this.showTipTray = false;
              }
            },
          })

        // 粗细按钮（当前宽度指示）
        Button((this.viewModel.isSelectionActive() ? this.selectionWidth :
          Math.round(this.viewModel.brushWidth)).toString())
          .width(48)
          .height(32)
          .fontSize(13)
          .margin({ left: 4, right: 4 })
          .enabled((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading &&
            !this.photoImportLeaseActive)
          .opacity((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.showWidthSlider = !this.viewModel.showWidthSlider;
            this.viewModel.showColorPicker = false;
            this.viewModel.setEyedropperActive(false);
          })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        if (!this.compact) {
          // 原版插入菜单序位：Add Files → Add Photo → Take Photo → Math（qc.java）
          Button($r('app.string.add_files'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onAddFiles();
            })
          Button($r('app.string.insert_photo'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onInsertPhotos();
            })
          Button($r('app.string.take_photo'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onTakePhoto();
            })
          Button($r('app.string.insert_math'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onInsertMath();
            })
          Divider().vertical(true).height(24).margin({ left: 8, right: 8 })
        }

        // Undo / Redo（T-021 实现功能）
        Button('↶')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canUndo &&
            !this.photoImportLeaseActive)
          .opacity(this.canUndo ? 1 : 0.4)
          // 原版 feature_note__toprighttoolbar_undo_action：撤销按钮描述。
          .accessibilityText($r('app.string.cd_undo_action'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.onUndo();
          })
          // 原版 x90 fsi.h(pq9.O, pos3)：undo/redo 手势提示锚定撤销按钮。
          .bindPopup(this.showTipUndoRedo, {
            builder: (): void => {
              this.OnboardingUndoTip()
            },
            placement: Placement.Left,
            mask: false,
            autoCancel: false,
            onStateChange: (event: PopupStateChangeEvent) => {
              this.showTipUndoRedo = event.isVisible;
            },
          })
        Button('↷')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canRedo &&
            !this.photoImportLeaseActive)
          .opacity(this.canRedo ? 1 : 0.4)
          // 原版 feature_note__toprighttoolbar_redo_action：重做按钮描述。
          .accessibilityText($r('app.string.cd_redo_action'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.onRedo();
          })
        // 原版 x90.g：share 图标紧随 undo/redo（ac4.L=NOTE_SHARE
        // PRODUCTION 级默认开启），点击打开分享格式面板。
        Button('↗')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(!this.photoImportLeaseActive)
          .accessibilityText($r('app.string.cd_share_action'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.showShareSheet = true;
          })
        }
        .height(48)
        .padding({ left: 8, right: 8 })
        .backgroundColor(this.resolveTokens().surface)
      }
      .width('100%')
      .height(48)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 弹层（颜色/粗细面板）
      if (this.viewModel.showColorPicker) {
        Row() {
          ColorPickerView({
            viewModel: this.viewModel,
            selectionMode: this.viewModel.isSelectionActive(),
            selectionColor: this.selectionColor,
            photoImportLeaseActive: this.photoImportLeaseActive,
            onSelectionColor: (color: number): void => this.onSelectionColor(color),
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.showWidthSlider) {
        Row() {
          WidthSlider({
            viewModel: this.viewModel,
            selectionMode: this.viewModel.isSelectionActive(),
            selectionWidth: this.selectionWidth,
            selectionMinimum: this.selectionWidthMinimum,
            selectionMaximum: this.selectionWidthMaximum,
            photoImportLeaseActive: this.photoImportLeaseActive,
            onSelectionWidth: (width: number): void => this.onSelectionWidth(width),
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.supportsBrushControls()) {
        Row() {
          this.StyleButton($r('app.string.style_mono'), BrushStyle.MONO)
          this.StyleButton($r('app.string.style_taper'), BrushStyle.TAPER)
          this.StyleButton($r('app.string.style_dash'), BrushStyle.DASH)
          this.StyleButton($r('app.string.style_dots'), BrushStyle.DOT)
        }
        .width('100%')
        .height(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.isLaserActive()) {
        // 原版 pni/uni.a：激光设置 = Tail / No Tail 分段开关。
        Row() {
          Button($r('app.string.laser_tail_label'))
            .height(30)
            .fontSize(13)
            .backgroundColor(this.viewModel.laserShowTail ?
              this.resolveTokens().accent : this.resolveTokens().control)
            .fontColor(this.viewModel.laserShowTail ?
              this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
            .enabled(!this.viewModel.toolStateLoading && !this.photoImportLeaseActive)
            .accessibilityText($r('app.string.laser_tail_mode'))
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.viewModel.setLaserShowTail(true).catch((e: Object): void => {
                console.error(`laser tail toggle failed: ${JSON.stringify(e)}`);
              });
            })
          Button($r('app.string.laser_no_tail_label'))
            .height(30)
            .fontSize(13)
            .margin({ left: 8 })
            .backgroundColor(!this.viewModel.laserShowTail ?
              this.resolveTokens().accent : this.resolveTokens().control)
            .fontColor(!this.viewModel.laserShowTail ?
              this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
            .enabled(!this.viewModel.toolStateLoading && !this.photoImportLeaseActive)
            .accessibilityText($r('app.string.laser_no_tail_mode'))
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.viewModel.setLaserShowTail(false).catch((e: Object): void => {
                console.error(`laser tail toggle failed: ${JSON.stringify(e)}`);
              });
            })
        }
        .width('100%')
        .height(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.isSelectionActive()) {
        Column() {
          Row() {
            Text($r('app.string.selection'))
            Button(this.viewModel.selectionIsFreehand ? $r('app.string.freehand') : $r('app.string.rectangle'))
              .height(30)
              .margin({ left: 12 })
              .enabled(!this.viewModel.toolStateLoading &&
                !this.photoImportLeaseActive)
              .onClick(() => {
                if (this.photoImportLeaseActive) {
                  return;
                }
                this.viewModel.setSelectionIsFreehand(!this.viewModel.selectionIsFreehand);
              })
          }
          Row() {
            this.SelectionStyleButton($r('app.string.style_mono'), BrushStyle.MONO)
            this.SelectionStyleButton($r('app.string.style_taper'), BrushStyle.TAPER)
            this.SelectionStyleButton($r('app.string.style_dash'), BrushStyle.DASH)
            this.SelectionStyleButton($r('app.string.style_dots'), BrushStyle.DOT)
          }
        }
        .width('100%')
        .height(72)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .bindSheet(this.showToolSettings, this.buildToolSettings(), {
      height: SheetSize.MEDIUM,
      showClose: false,
    })
    .bindSheet(this.showShareSheet, this.buildShareSheet(), {
      height: SheetSize.MEDIUM,
      showClose: false,
      // 原版 b7d.j()/f()：面板关闭即回 MAIN 屏并清空页集合/缩略图
      // 缓存——下次打开是全新会话（v6d 随 sheet 重建）。
      onDisappear: (): void => {
        this.shareScreen = 'main';
        this.sharePageIndexes = null;
        this.sharePassword = null;
        this.sharePasswordDraft = '';
        this.sharePasswordConfirm = '';
        this.sharePasswordMismatch = false;
        this.shareFormat = 'pdf';
        this.shareIncludeBackground = false;
        this.shareIncludeRecording = true;
      },
    })
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.compact = (newArea.width as number) < 600;
    })
  }

  private buildCompactToolMenu(): MenuElement[] {
    return [
      { value: $r('app.string.whole_eraser'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.WHOLE_ERASER);
      } },
      { value: $r('app.string.partial_eraser'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.PARTIAL_ERASER);
      } },
      { value: $r('app.string.selection'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.SELECTION);
      } },
      { value: $r('app.string.text'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.DEFAULT);
      } },
      { value: $r('app.string.add_files'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onAddFiles();
      } },
      { value: $r('app.string.insert_photo'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onInsertPhotos();
      } },
      { value: $r('app.string.take_photo'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onTakePhoto();
      } },
      { value: $r('app.string.insert_math'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onInsertMath();
      } },
    ];
  }

  // 每个可见工具行一个按钮；tool_id 级选中高亮支持同类型重复工具。
  @Builder
  StateToolButton(label: ResourceStr, tool: ToolState) {
    Button(label)
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId);
        // 原版 pq9 通用宿主：文本/荧光笔工具首次选中的使用提示。
        if (tool.toolId === 'text' &&
          !this.tipSeen(OnboardingTooltipKind.FIRST_TEXT)) {
          this.onboardingTipToolId = tool.toolId;
          this.onboardingTipToolKind = OnboardingTooltipKind.FIRST_TEXT;
          this.onboardingTipToolText =
            $r('app.string.data_onboarding__first_text_tooltip_text');
          this.showTipTool = true;
        } else if (tool.toolType === ToolType.HIGHLIGHTER &&
          !this.tipSeen(OnboardingTooltipKind.FIRST_HIGHLIGHTER)) {
          this.onboardingTipToolId = tool.toolId;
          this.onboardingTipToolKind = OnboardingTooltipKind.FIRST_HIGHLIGHTER;
          this.onboardingTipToolText =
            $r('app.string.data_onboarding__first_highlighter_tooltip_text');
          this.showTipTool = true;
        }
      })
      .bindPopup(this.showTipTool && this.onboardingTipToolId === tool.toolId, {
        builder: (): void => {
          this.OnboardingToolTip()
        },
        placement: Placement.Bottom,
        mask: false,
        autoCancel: false,
        onStateChange: (event: PopupStateChangeEvent) => {
          if (!event.isVisible) {
            this.showTipTool = false;
          }
        },
      })
  }

  // WHOLE_ERASER 行渲染为 整笔/局部 两个模式按钮（与原版 eraserIsPartial 模式位对应）。
  @Builder
  EraserToolButtons(tool: ToolState) {
    Button($r('app.string.whole_eraser'))
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) && !this.viewModel.eraserIsPartial ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) && !this.viewModel.eraserIsPartial ?
        this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId).then((selected: boolean): void => {
          if (selected) {
            this.viewModel.setEraserIsPartial(false);
          }
        });
      })
    Button($r('app.string.partial_eraser'))
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) && this.viewModel.eraserIsPartial ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) && this.viewModel.eraserIsPartial ?
        this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId).then((selected: boolean): void => {
          if (selected) {
            this.viewModel.setEraserIsPartial(true);
          }
        });
      })
  }

  // 原版 s6d 分享格式序：LINK、PDF、NOTE、JPG、PNG（atc case3~7）。
  // NOTE 走既有 NoteExporter 管线；JPG/PNG 走页级栅格化导出
  // （Phase 642）；PDF 走整册逐页栅格化导出（Phase 643）；
  // LINK 置灰 fail-closed（账号后端未备，见 ADR-0608/0609/0610）。
  // 原版 b7d.q(i, z)：页索引 toggle——基集取 v6d.l，null 时先物化
  // 全页集合（rh8.V(0, m) 等价），再按 z 增删。
  private toggleSharePage(pageIndex: number): void {
    const base: number[] = this.sharePageIndexes === null ?
      this.sharePages.map((_page: PageInfo, index: number): number => index) :
      this.sharePageIndexes.slice();
    const at: number = base.indexOf(pageIndex);
    if (at >= 0) {
      base.splice(at, 1);
    } else {
      base.push(pageIndex);
      base.sort((a: number, b: number): number => a - b);
    }
    this.sharePageIndexes = base;
  }

  // 原版 v6d.l 为空集（整册）↔ 显式子集的判定：pj 事件的 partial 位
  // = set != null && set.size() != m。
  private shareSelectionLabel(): ResourceStr {
    const selected: number[] | null = this.sharePageIndexes;
    if (selected === null || selected.length === this.sharePages.length) {
      return $r('app.string.share_range_all');
    }
    return $r('app.string.share_range_selected', selected.length,
      this.sharePages.length);
  }

  @Builder
  buildShareSheet() {
    Column() {
      if (this.shareScreen === 'pages') {
        this.buildSharePagePicker()
      } else if (this.shareScreen === 'password') {
        this.buildSharePassword()
      } else {
        this.buildShareMain()
      }
    }
    .width('100%')
    .padding({ bottom: 24 })
    .backgroundColor(this.resolveTokens().surface)
  }

  // 原版 r6d.MAIN 屏：标题 + 页范围行（All / X of Y）+ 五格式行。
  @Builder
  buildShareMain() {
    Column() {
      Text($r('app.string.share_sheet_title'))
        .fontSize(16)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 16, bottom: 12 })
      // 原版格式 chip 行（dih.j → x90.b 单选 chip 组）：v6d.c 切换
      // 驱动下方分格式选项区；LINK 置灰不可选（fail-closed）。
      Row() {
        this.ShareFormatChip($r('app.string.share_link'), 'link', false)
        this.ShareFormatChip($r('app.string.share_pdf'), 'pdf', true)
        this.ShareFormatChip($r('app.string.share_note'), 'note', true)
        this.ShareFormatChip($r('app.string.share_jpg'), 'jpg', true)
        this.ShareFormatChip($r('app.string.share_png'), 'png', true)
      }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 8 })
      // 分格式选项区（dih.h=PDF / dih.d=NOTE / dih.a=JPG|PNG /
      // dih.b=LINK）：页范围行与密码行按原版分支归属各自格式。
      if (this.shareFormat === 'pdf') {
        this.ShareRangeRow()
        this.ShareToggleRow($r('app.string.share_include_background'),
          this.shareIncludeBackground, 'bg')
        this.ShareToggleRow($r('app.string.share_include_recording'),
          this.shareIncludeRecording, 'rec')
        this.SharePasswordRow()
      } else if (this.shareFormat === 'note') {
        this.ShareToggleRow($r('app.string.share_include_recording'),
          this.shareIncludeRecording, 'rec')
      } else if (this.shareFormat === 'jpg' || this.shareFormat === 'png') {
        this.ShareRangeRow()
        this.ShareToggleRow($r('app.string.share_include_background'),
          this.shareIncludeBackground, 'bg')
      } else {
        Text($r('app.string.share_link_unavailable'))
          .fontSize(13)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ left: 24, right: 24, top: 8, bottom: 8 })
      }
      // 底部动作行（dih.i/g6d）：Cancel + "Share X"（按选中格式取
      // ui_share__action_* 标签）；LINK 禁用导出。
      Row() {
        Text($r('app.string.share_cancel'))
          .fontSize(15)
          .fontColor(this.resolveTokens().textSecondary)
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => {
            this.showShareSheet = false;
          })
        Blank()
        Text(this.shareActionLabel())
          .fontSize(15)
          .fontColor(this.shareFormat === 'link' ?
            this.resolveTokens().textSecondary : this.resolveTokens().accent)
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => {
            this.dispatchShare();
          })
      }
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
  }

  // 原版主屏页范围行（dih.e/v8 case17）：Page range 标签 +
  // All/"%d of %d" 值 + 点击进 PAGE_SELECTION。PDF/JPG/PNG 归属。
  @Builder
  ShareRangeRow() {
    Row() {
      Text($r('app.string.share_page_range'))
        .fontSize(15)
        .fontColor(this.resolveTokens().textPrimary)
      Blank()
      Text(this.shareSelectionLabel())
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
      Text('›')
        .fontSize(16)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ left: 4 })
    }
      .width('100%')
      .height(44)
      .padding({ left: 24, right: 24 })
      .onClick(() => {
        this.shareScreen = 'pages';
      })
  }

  // 原版主屏密码行（zy7 case17）：v6d.k!=null → On 否则 Off；
  // 点击进 PASSWORD_ENTRY 回填既有密码。仅 PDF 归属。
  @Builder
  SharePasswordRow() {
    Row() {
      Text($r('app.string.share_password'))
        .fontSize(15)
        .fontColor(this.resolveTokens().textPrimary)
      Blank()
      Text(this.sharePassword !== null ?
        $r('app.string.share_password_on') : $r('app.string.share_password_off'))
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
      Text('›')
        .fontSize(16)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ left: 4 })
    }
      .width('100%')
      .height(44)
      .padding({ left: 24, right: 24 })
      .onClick(() => {
        this.sharePasswordDraft = this.sharePassword !== null ?
          this.sharePassword : '';
        this.sharePasswordConfirm = this.sharePassword !== null ?
          this.sharePassword : '';
        this.sharePasswordMismatch = false;
        this.shareScreen = 'password';
      })
  }

  // 原版 include_* 行（fw2 标签 + j6d e9e.a 开关）：v6d.i（'bg'）
  // 或 v6d.j（'rec'）布尔绑定。
  @Builder
  ShareToggleRow(label: ResourceStr, value: boolean, which: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.resolveTokens().textPrimary)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((enabled: boolean) => {
          if (which === 'bg') {
            this.shareIncludeBackground = enabled;
          } else {
            this.shareIncludeRecording = enabled;
          }
        })
    }
      .width('100%')
      .height(44)
      .padding({ left: 24, right: 24 })
  }

  // 原版格式 chip（x90.b 单选组单元）：选中态 accent 底/白字，
  // LINK 置灰不可点。
  @Builder
  ShareFormatChip(label: ResourceStr, format: string, supported: boolean) {
    Text(label)
      .fontSize(13)
      .fontColor(!supported ? this.resolveTokens().textSecondary :
        (this.shareFormat === format ? '#FFFFFF' :
          this.resolveTokens().textPrimary))
      .backgroundColor(this.shareFormat === format && supported ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .borderRadius(14)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .opacity(supported ? 1 : 0.4)
      .onClick(() => {
        if (!supported) {
          return;
        }
        this.shareFormat = format;
      })
  }

  // 原版 r6d.PAGE_SELECTION 屏：页缩略图栅格逐页勾选（b7d.q），
  // 全选/取消全选 + 计数头（X of Y）+ Done 回 MAIN。
  @Builder
  buildSharePagePicker() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(20)
          .fontColor(this.resolveTokens().accent)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.shareScreen = 'main';
          })
        Text($r('app.string.share_range_selected',
          this.sharePageIndexes === null ? this.sharePages.length :
            this.sharePageIndexes.length,
          this.sharePages.length))
          .fontSize(14)
          .fontColor(this.resolveTokens().textPrimary)
        Blank()
        Text(this.sharePageIndexes === null ?
          $r('app.string.pages_deselect_all') : $r('app.string.pages_select_all'))
          .fontSize(13)
          .fontColor(this.resolveTokens().accent)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.sharePageIndexes = this.sharePageIndexes === null ? [] : null;
          })
        Text($r('app.string.pages_done'))
          .fontSize(13)
          .fontColor(this.resolveTokens().accent)
          .padding({ left: 12, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            this.shareScreen = 'main';
          })
      }
        .width('100%')
      Grid() {
        ForEach(this.sharePages, (page: PageInfo, index: number) => {
          GridItem() {
            SharePageCell({
              pageIndex: index,
              page: page,
              checked: this.sharePageIndexes === null ||
                this.sharePageIndexes.indexOf(index) >= 0,
              onRequest: this.onShareThumb,
              onToggle: (pageIndex: number): void => {
                this.toggleSharePage(pageIndex);
              },
            })
          }
        }, (page: PageInfo): string => page.pageId)
      }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding({ left: 12, right: 12, bottom: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 原版 r6d.PASSWORD_ENTRY 屏（dih.g）：Password 标题 + "Protect
  // your PDF with a password." 副题 + Enter/Confirm 两密码框 +
  // mismatch 错误 + Save（b7d.o(str)：长度0→null；不一致→mismatch；
  // 一致→写回 v6d.k 回 MAIN）/ Remove（已设时清空）。
  @Builder
  buildSharePassword() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(20)
          .fontColor(this.resolveTokens().accent)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.shareScreen = 'main';
          })
        Text($r('app.string.share_password'))
          .fontSize(16)
          .fontColor(this.resolveTokens().textPrimary)
        Blank()
        if (this.sharePassword !== null) {
          Text($r('app.string.share_password_remove'))
            .fontSize(13)
            .fontColor(this.resolveTokens().accent)
            .padding({ left: 12, right: 8, top: 8, bottom: 8 })
            .onClick(() => {
              this.sharePassword = null;
              this.sharePasswordDraft = '';
              this.sharePasswordConfirm = '';
              this.sharePasswordMismatch = false;
              this.shareScreen = 'main';
            })
        }
        Text($r('app.string.share_password_save'))
          .fontSize(13)
          .fontColor(this.sharePasswordDraft.length > 0 ?
            this.resolveTokens().accent : this.resolveTokens().textSecondary)
          .padding({ left: 12, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            // 原版 Save 按钮 draft 为空时禁用（kw1: z=draft.length>0）；
            // kv1 校验：draft==confirm 且非空 → b7d.o(draft)，否则
            // mismatch 标志置位。空 draft 点击为 no-op（禁用等价）。
            if (this.sharePasswordDraft.length === 0) {
              return;
            }
            if (this.sharePasswordDraft !== this.sharePasswordConfirm) {
              this.sharePasswordMismatch = true;
              return;
            }
            this.sharePassword = this.sharePasswordDraft;
            this.sharePasswordMismatch = false;
            this.shareScreen = 'main';
          })
      }
        .width('100%')
      Text($r('app.string.share_password_subtitle'))
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ left: 24, right: 24, top: 8, bottom: 12 })
      TextInput({ placeholder: $r('app.string.share_password_enter'),
        text: this.sharePasswordDraft })
        .type(InputType.Password)
        .height(40)
        .fontSize(14)
        .margin({ left: 24, right: 24, bottom: 8 })
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().control)
        .borderRadius(10)
        .onChange((value: string) => {
          this.sharePasswordDraft = value;
          this.sharePasswordMismatch = false;
        })
      TextInput({ placeholder: $r('app.string.share_password_confirm'),
        text: this.sharePasswordConfirm })
        .type(InputType.Password)
        .height(40)
        .fontSize(14)
        .margin({ left: 24, right: 24, bottom: 8 })
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().control)
        .borderRadius(10)
        .onChange((value: string) => {
          this.sharePasswordConfirm = value;
          this.sharePasswordMismatch = false;
        })
      if (this.sharePasswordMismatch) {
        Text($r('app.string.share_password_mismatch'))
          .fontSize(12)
          .fontColor('#D32F2F')
          .margin({ left: 24, right: 24, bottom: 8 })
      }
    }
    .width('100%')
  }

  // 原版 "Share X" 动作（g6d）：按 v6d.c 选中格式分发；NOTE 恒整册
  // （v6d.l 不作用于 .note 归档）；LINK 不可达（chip 禁用）。
  private dispatchShare(): void {
    if (this.shareFormat === 'link') {
      return;
    }
    this.showShareSheet = false;
    if (this.shareFormat === 'note') {
      this.onShareNote(this.shareIncludeRecording);
    } else if (this.shareFormat === 'pdf') {
      this.onSharePdf(this.sharePageIndexes, this.sharePassword,
        this.shareIncludeBackground);
    } else {
      this.onShareImage(this.shareFormat, this.sharePageIndexes,
        this.shareIncludeBackground);
    }
  }

  // 原版 s6d.L（单笔记 action 标签）→ "Share PDF" 等。
  private shareActionLabel(): ResourceStr {
    if (this.shareFormat === 'note') {
      return $r('app.string.share_action_note');
    }
    if (this.shareFormat === 'jpg') {
      return $r('app.string.share_action_jpg');
    }
    if (this.shareFormat === 'png') {
      return $r('app.string.share_action_png');
    }
    if (this.shareFormat === 'link') {
      return $r('app.string.share_action_link');
    }
    return $r('app.string.share_action_pdf');
  }

  @Builder
  buildToolSettings() {
    ToolboxSettingsDialog({
      viewModel: this.viewModel,
      onClose: (): void => {
        this.showToolSettings = false;
      },
      tapeCount: this.tapeCount,
      anyTapeRevealed: this.anyTapeRevealed,
      onTapeToggle: (): void => {
        this.onTapeToggle();
      },
    })
  }

  @Builder
  StyleButton(label: ResourceStr, style: BrushStyle) {
    Button(label)
      .height(30)
      .fontSize(12)
      .borderRadius(4)
      .margin({ left: 2, right: 2 })
      .backgroundColor(this.viewModel.brushStyle === style ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.viewModel.brushStyle === style ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.setBrushStyle(style);
      })
  }

  @Builder
  SelectionStyleButton(label: ResourceStr, style: BrushStyle) {
    Button(label)
      .height(30)
      .fontSize(12)
      .borderRadius(4)
      .margin({ left: 2, right: 2 })
      .backgroundColor(this.selectionStyle === style ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.selectionStyle === style ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive &&
        (style !== BrushStyle.TAPER || this.selectionVariableStyleEnabled))
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onSelectionStyle(style);
      })
  }

  aboutToAppear(): void {
    const tipContext = getContext(this) as common.UIAbilityContext;
    this.onboardingStore = new OnboardingTooltipStore(tipContext);
    this.onboardingStore.getSeenKinds().then((seen: string[]): void => {
      this.onboardingSeen = seen;
      this.onboardingSeenReady = true;
      this.refreshOnboardingTips();
    }).catch((e: Error): void => {
      console.error('onboarding seen load failed: ' + JSON.stringify(e));
    });
  }

  private tipSeen(kind: OnboardingTooltipKind): boolean {
    return this.onboardingSeen.indexOf(kind) !== -1;
  }

  // 原版 fsi.g 内部校验 !seen；站点上下文由各触发点判定。
  private refreshOnboardingTips(): void {
    if (!this.onboardingSeenReady) {
      return;
    }
    // rh8 e5f：编辑器挂载即满足 NEW_NOTE。
    if (!this.tipSeen(OnboardingTooltipKind.NEW_NOTE)) {
      this.showTipNewNote = true;
    }
    // x90 z7：任一页有内容 → 页面管理器（FIRST_IMPORT）气泡。
    if (this.noteHasContent && !this.tipSeen(OnboardingTooltipKind.FIRST_IMPORT)) {
      this.showTipImport = true;
    }
    // x90 gl8Var5：undo 可用 → FIRST_UNDO_REDO 气泡。
    if (this.canUndo && !this.tipSeen(OnboardingTooltipKind.FIRST_UNDO_REDO)) {
      this.showTipUndoRedo = true;
    }
  }

  private onNoteHasContentTip(): void {
    if (this.noteHasContent) {
      this.refreshOnboardingTips();
    }
  }

  private onCanUndoTip(): void {
    if (this.canUndo) {
      this.refreshOnboardingTips();
    }
  }

  // 原版 js7："Got it" 关闭 → 对应 pq9 写入 onboardingTooltipSeen 并持久化。
  private dismissOnboardingTip(kind: OnboardingTooltipKind): void {
    if (this.onboardingSeen.indexOf(kind) === -1) {
      this.onboardingSeen = this.onboardingSeen.concat([kind]);
    }
    if (kind === OnboardingTooltipKind.NEW_NOTE) {
      this.showTipNewNote = false;
    } else if (kind === OnboardingTooltipKind.FIRST_TRAY_OPENED) {
      this.showTipTray = false;
    } else if (kind === OnboardingTooltipKind.FIRST_TEXT ||
      kind === OnboardingTooltipKind.FIRST_HIGHLIGHTER) {
      this.showTipTool = false;
    } else if (kind === OnboardingTooltipKind.FIRST_UNDO_REDO) {
      this.showTipUndoRedo = false;
    } else if (kind === OnboardingTooltipKind.FIRST_IMPORT) {
      this.showTipImport = false;
    }
    const store: OnboardingTooltipStore | null = this.onboardingStore;
    if (store !== null) {
      store.markSeen(kind).catch((e: Error): void => {
        console.error('onboarding markSeen failed: ' + JSON.stringify(e));
      });
    }
  }

  // 原版 zy7/tpe.b：深色气泡 + 本地化文案 + "Got it"；mask:false 保持
  // 原版的非模态语义（提示期间锚点控件仍可点按）。
  @Builder
  private OnboardingAnchorTip() {
    OnboardingTipBubble({
      tipText: this.showTipNewNote ?
        $r('app.string.data_onboarding__new_note_tooltip_text') :
        $r('app.string.data_onboarding__first_tray_opened_tooltip_text'),
      onGotIt: (): void => {
        this.dismissOnboardingTip(this.showTipNewNote ?
          OnboardingTooltipKind.NEW_NOTE : OnboardingTooltipKind.FIRST_TRAY_OPENED);
      },
    })
  }

  @Builder
  private OnboardingToolTip() {
    OnboardingTipBubble({
      tipText: this.onboardingTipToolText,
      onGotIt: (): void => {
        this.dismissOnboardingTip(this.onboardingTipToolKind);
      },
    })
  }

  @Builder
  private OnboardingUndoTip() {
    OnboardingTipBubble({
      tipText: $r('app.string.data_onboarding__first_undo_redo_tooltip_text'),
      onGotIt: (): void => {
        this.dismissOnboardingTip(OnboardingTooltipKind.FIRST_UNDO_REDO);
      },
    })
  }

  @Builder
  private OnboardingImportTip() {
    OnboardingTipBubble({
      tipText: $r('app.string.data_onboarding__first_import_tooltip_text'),
      onGotIt: (): void => {
        this.dismissOnboardingTip(OnboardingTooltipKind.FIRST_IMPORT);
      },
    })
  }

}

// 分享页选择栅格 cell：对应原版 r6d.PAGE_SELECTION 屏的页缩略图格
// （b7d.l 缩略图窗口 + q(i,z) 勾选切换）；只承担勾选语义，不带
// 页操作上下文菜单（那是 content-manager 概览面板的职责）。
@Component
struct SharePageCell {
  @Prop pageIndex: number = 0;
  page?: PageInfo;
  @Prop checked: boolean = true;
  onRequest: (page: PageInfo) => Promise<PixelMap | null> =
    (_page: PageInfo): Promise<PixelMap | null> => Promise.resolve(null);
  onToggle: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  @State private pixelMap: PixelMap | null = null;
  @State private loadingFailed: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private loadGeneration: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  aboutToDisappear(): void {
    this.loadGeneration++;
    const pm: PixelMap | null = this.pixelMap;
    this.pixelMap = null;
    if (pm !== null) {
      pm.release().catch((): void => { });
    }
  }

  private reload(): void {
    const page = this.page;
    if (page === undefined) {
      return;
    }
    const generation: number = ++this.loadGeneration;
    this.loadingFailed = false;
    this.onRequest(page)
      .then((pm: PixelMap | null): void => {
        if (generation !== this.loadGeneration) {
          if (pm !== null) {
            pm.release().catch((): void => { });
          }
          return;
        }
        const old: PixelMap | null = this.pixelMap;
        this.pixelMap = pm;
        this.loadingFailed = pm === null;
        if (old !== null) {
          old.release().catch((): void => { });
        }
      })
      .catch((): void => {
        if (generation === this.loadGeneration) {
          this.loadingFailed = true;
        }
      });
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Stack() {
        if (this.pixelMap !== null) {
          Image(this.pixelMap)
            .width('100%')
            .aspectRatio(0.75)
            .objectFit(ImageFit.Contain)
        } else {
          Column()
            .width('100%')
            .aspectRatio(0.75)
            .backgroundColor('#F5F5F5')
        }
        // 勾选指示与 PageOverviewCell 选择态同款：选中=实心 ✓，
        // 未选中=空心圈。
        Text(this.checked ? '✓' : '')
          .fontSize(12)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(this.checked ?
            this.resolveTokens().accent : '#66000000')
          .border({ width: 1, color: Color.White, radius: 10 })
          .position({ x: 4, y: 4 })
      }
      .width('100%')
      .borderRadius(6)
      .clip(true)
      .border({
        width: this.checked ? 2 : 1,
        color: this.checked ? this.resolveTokens().accent : '#E0E0E0',
        radius: 6,
      })
      Text((this.pageIndex + 1).toString())
        .fontSize(11)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 4 })
    }
    .width('100%')
    .opacity(this.checked ? 1 : 0.55)
    .onClick(() => {
      this.onToggle(this.pageIndex);
    })
  }
}
