// Phase 534 toolbox customization surface — mirrors the original settings sheet
// (o6f.java): visible tools with reorder/hide/duplicate/delete, a hidden-tools
// section with show, the 12-tool "max-reached" hint, and reset-to-default.
import { ToolState, ToolType, TRAY_TYPE_PRIMARY, TRAY_TYPE_SECONDARY } from '../../core/model/BrushTypes';
import { EditorViewModel } from './EditorViewModel';
import { TapePatternPicker } from './TapePatternPicker';
import { ShapeKindPicker } from './ShapeKindPicker';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';

export function toolTypeLabel(toolType: ToolType): Resource {
  switch (toolType) {
    case ToolType.PEN: return $r('app.string.pen');
    // 原版 ui_tools__calligraphy = "Calligraphy"（eti.G 凿尖笔工具标签）。
    case ToolType.CALLIGRAPHY: return $r('app.string.calligraphy');
    // 原版 ui_tools__shape = "Shape"（eti.T 形状工具标签，h5g.java 工具项）。
    case ToolType.SHAPE: return $r('app.string.shape');
    case ToolType.PENCIL: return $r('app.string.pencil');
    case ToolType.HIGHLIGHTER: return $r('app.string.highlighter');
    case ToolType.WHOLE_ERASER: return $r('app.string.eraser');
    case ToolType.PARTIAL_ERASER: return $r('app.string.partial_eraser');
    case ToolType.SELECTION: return $r('app.string.selection');
    case ToolType.LASER: return $r('app.string.laser');
    // 原版 ui_tools__zoom = "Zoom"（a6f.U 工具标签）。
    case ToolType.ZOOM: return $r('app.string.tool_zoom');
    case ToolType.REVIEW: return $r('app.string.tape_tool');
    // 原版 fie→yz.j(ui_text__add_text)：文本工具项标签为 "Add Text"。
    default: return $r('app.string.add_text');
  }
}

@Component
export struct ToolboxSettingsDialog {
  @ObjectLink viewModel: EditorViewModel;
  onClose: () => void = () => {
  };
  // 原版 o94 case14/ipi.b：胶带工具设置页内的 Hide/Reveal Tapes 行——
  // 作用于全部可见 tape（空集 no-op），标签随已揭示态翻转。
  @Prop tapeCount: number = 0;
  @Prop anyTapeRevealed: boolean = false;
  onTapeToggle: () => void = () => {
  };
  @State visibleTools: ToolState[] = [];
  @State hiddenTools: ToolState[] = [];
  @State primaryFull: boolean = false;
  // 原版 mh9 → t7f：REVIEW 工具 ⋯ 菜单的"Tape Pattern"项打开 9 图案选择页。
  @State tapePatternToolId: string = '';
  // 1.4.2 h5g：SHAPE 工具 ⋯ 菜单的"Shape"项打开 6 类选择页。
  @State shapeKindToolId: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.refresh();
  }

  private refresh(): void {
    this.visibleTools = this.viewModel.visibleToolStates();
    this.hiddenTools = this.viewModel.hiddenToolStates();
    this.primaryFull = this.viewModel.isPrimaryTrayFull();
  }

  private runOp(operation: Promise<boolean>): void {
    operation.then((): void => this.refresh());
  }

  private trayToggleTarget(tool: ToolState): number {
    return tool.trayType === TRAY_TYPE_PRIMARY ? TRAY_TYPE_SECONDARY : TRAY_TYPE_PRIMARY;
  }

  private findToolById(toolId: string): ToolState | null {
    for (const tool of this.visibleTools) {
      if (tool.toolId === toolId) {
        return tool;
      }
    }
    for (const tool of this.hiddenTools) {
      if (tool.toolId === toolId) {
        return tool;
      }
    }
    return null;
  }

  // Per-row action menu (o94 parity): tray switch, hide, duplicate, delete.
  private toolMenu(tool: ToolState): MenuElement[] {
    const items: MenuElement[] = [
      {
        value: tool.trayType === TRAY_TYPE_PRIMARY ?
          $r('app.string.move_to_secondary') : $r('app.string.move_to_primary'),
        action: (): void => {
          this.runOp(this.viewModel.moveToolToIndex(tool.toolId,
            this.trayToggleTarget(tool), 999));
        },
      },
      {
        // 原版 xc2：show_tool→show / hide_tool→hide（当前态图标）。
        value: $r('app.string.hide_tool'),
        icon: $r('app.media.menuicon_hide'),
        action: (): void => {
          this.runOp(this.viewModel.hideTool(tool.toolId));
        },
      },
      {
        // 原版 o94 case259：duplicate_tool → ui_designsystem__duplicate。
        value: $r('app.string.duplicate_tool'),
        icon: $r('app.media.selmenu_duplicate'),
        action: (): void => {
          this.runOp(this.viewModel.duplicateTool(tool.toolId));
        },
      },
    ];
    // 原版胶带工具设置行的图案项（o94/lfe.b 预览 → mh9 打开选择页）。
    if (tool.toolType === ToolType.REVIEW) {
      items.push({
        value: $r('app.string.tape_patterns'),
        action: (): void => {
          this.tapePatternToolId = tool.toolId;
        },
      });
      // 原版 o94 case14/ipi.b：同一设置面内的 Hide/Reveal Tapes 行
      // （oh9 → np0 case5 全量 toggle）；与编辑页 ⋮ 菜单共用同一信号。
      if (this.tapeCount > 0) {
        items.push({
          // 原版 o94 279/283：图标反映当前态——hide_tapes 配 tape_reveal、
          // reveal_tapes 配 tape_conceal。
          value: this.anyTapeRevealed ?
            $r('app.string.hide_tapes') : $r('app.string.reveal_tapes'),
          icon: this.anyTapeRevealed ?
            $r('app.media.menuicon_tape_reveal') : $r('app.media.menuicon_tape_conceal'),
          action: (): void => {
            this.onTapeToggle();
          },
        });
      }
    }
    // 原版 1.4.2 h5g：SHAPE 工具 ⋯ 菜单的"Shape"项 → 6 类选择页。
    if (tool.toolType === ToolType.SHAPE) {
      items.push({
        value: $r('app.string.shape'),
        action: (): void => {
          this.shapeKindToolId = tool.toolId;
        },
      });
    }
    if (this.viewModel.canDeleteTool(tool.toolId)) {
      items.push({
        // 原版 xc2 z2 分支：delete_tool → ue4.z() = trash。
        value: $r('app.string.delete_tool'),
        icon: $r('app.media.selmenu_delete'),
        action: (): void => {
          this.runOp(this.viewModel.deleteTool(tool.toolId));
        },
      });
    }
    return items;
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.toolbox_settings'))
          .fontSize(16)
          .fontColor(this.resolveTokens().textPrimary)
        Blank()
        Button() {
          // 原版 ue4.u = ui_designsystem__close_med_regular 关闭图标。
          ToolGlyph({
            glyph: 'close_med_regular',
            contentColor: this.resolveTokens().textPrimary,
            iconSize: 18,
          })
        }
          .height(32)
          // 原版 feature_note_toolbox__settings_close：关闭工具设置。
          .accessibilityText($r('app.string.close'))
          .onClick(() => this.onClose())
      }
      .width('100%')
      .padding({ bottom: 8 })

      if (this.primaryFull) {
        Text($r('app.string.tool_max_reached'))
          .fontSize(12)
          .fontColor(this.resolveTokens().accent)
          .width('100%')
          .padding({ bottom: 6 })
      }

      if (this.tapePatternToolId.length > 0) {
        TapePatternPicker({
          tool: this.findToolById(this.tapePatternToolId),
          viewModel: this.viewModel,
          onClose: (): void => {
            this.tapePatternToolId = '';
            this.refresh();
          },
        })
      } else if (this.shapeKindToolId.length > 0) {
        ShapeKindPicker({
          tool: this.findToolById(this.shapeKindToolId),
          viewModel: this.viewModel,
          onClose: (): void => {
            this.shapeKindToolId = '';
            this.refresh();
          },
        })
      } else {
      Scroll() {
        Column() {
          ForEach(this.visibleTools, (tool: ToolState) => {
            Row() {
              Text(toolTypeLabel(tool.toolType))
                .fontSize(14)
                .fontColor(this.resolveTokens().textPrimary)
                .layoutWeight(1)
              // 上移/下移为 Harmony 等价控件（原版 ui_designsystem__drag_handle
              // 拖拽重排在对话框内以按钮近似）。▲ 用 chevron_down 旋转 180°。
              Button() {
                ToolGlyph({
                  glyph: 'chevron_down',
                  contentColor: this.resolveTokens().textPrimary,
                  iconSize: 18,
                })
              }
                .height(28)
                .margin({ left: 2, right: 2 })
                .rotate({ angle: 180 })
                .enabled(tool.trayIndex > 0)
                .opacity(tool.trayIndex > 0 ? 1 : 0.4)
                .accessibilityText($r('app.string.move_tool_up'))
                .onClick(() => {
                  this.runOp(this.viewModel.moveToolToIndex(tool.toolId, tool.trayType,
                    tool.trayIndex - 1));
                })
              Button() {
                ToolGlyph({
                  glyph: 'chevron_down',
                  contentColor: this.resolveTokens().textPrimary,
                  iconSize: 18,
                })
              }
                .height(28)
                .margin({ left: 2, right: 2 })
                .accessibilityText($r('app.string.move_tool_down'))
                .onClick(() => {
                  this.runOp(this.viewModel.moveToolToIndex(tool.toolId, tool.trayType,
                    tool.trayIndex + 1));
                })
              Button() {
                // 原版单项工具溢出菜单 = ui_designsystem__more（三点）。
                ToolGlyph({
                  glyph: 'more',
                  contentColor: this.resolveTokens().textPrimary,
                  iconSize: 18,
                })
              }
                .height(28)
                .margin({ left: 2, right: 2 })
                // 原版 feature_note__toolbar_more_menu：单项工具溢出菜单。
                .accessibilityText($r('app.string.toolbar_more_menu'))
                .bindMenu(this.toolMenu(tool))
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (tool: ToolState): string => tool.toolId)

          if (this.hiddenTools.length > 0) {
            Text($r('app.string.hidden_tools'))
              .fontSize(13)
              .fontColor(this.resolveTokens().textPrimary)
              .opacity(0.6)
              .width('100%')
              .padding({ top: 10, bottom: 4 })
            ForEach(this.hiddenTools, (tool: ToolState) => {
              Row() {
                Text(toolTypeLabel(tool.toolType))
                  .fontSize(14)
                  .fontColor(this.resolveTokens().textPrimary)
                  .opacity(0.6)
                  .layoutWeight(1)
                Button($r('app.string.show_tool'))
                  .height(28)
                  .fontSize(12)
                  .margin({ left: 2, right: 2 })
                  .onClick(() => {
                    this.runOp(this.viewModel.showTool(tool.toolId));
                  })
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            }, (tool: ToolState): string => tool.toolId)
          }
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: 320 })
      .scrollBar(BarState.Auto)

      Button($r('app.string.reset_to_default'))
        .height(32)
        .fontSize(13)
        .margin({ top: 10 })
        .onClick(() => {
          this.runOp(this.viewModel.resetToolsToDefaults());
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }
}
