// T-019 颜色选择器（原版 FavoriteColorWell + RecentColorWell + 预设色板）
// 注意：struct 名不能使用保留标签名 ColorPicker，用 ColorPickerView
import { EditorViewModel } from '../editor/EditorViewModel';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { PEN_PALETTE_PACKS, PEN_PALETTE_PACKS_ADAPTIVE } from '../../data/PenPalettes';

@Component
export struct ColorPickerView {
  @ObjectLink viewModel: EditorViewModel;
  @Prop selectionMode: boolean = false;
  @Prop selectionColor: number = -16777216;
  @Prop photoImportLeaseActive: boolean = false;
  onSelectionColor: (color: number) => void = (_color: number): void => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private presetColors: number[] = [
    -16777216,   // 黑
    -7829368,    // 灰
    -65536,      // 红
    -26368,      // 橙
    -256,        // 黄
    -16744448,   // 绿
    -16711681,   // 青
    -16776961,   // 蓝
    -8388480,    // 紫
    -16181,      // 粉
    -10011977,   // 棕
    -1,          // 白
  ];

  // 原版 pen_palette_color_*/pen_swatch_color_*：预设色点名（a11y）。
  // Harmony 12 预设按色相映射到原版命名（pink/brown 用 swatch/palette
  // 中语义等价项）。
  private presetColorName(color: number): Resource | null {
    switch (color) {
      case -16777216: return $r('app.string.pen_palette_color_black');
      case -7829368: return $r('app.string.pen_palette_color_gray');
      case -65536: return $r('app.string.pen_palette_color_red');
      case -26368: return $r('app.string.pen_palette_color_orange');
      case -256: return $r('app.string.pen_palette_color_yellow');
      case -16744448: return $r('app.string.pen_palette_color_green');
      case -16711681: return $r('app.string.pen_palette_color_turquoise');
      case -16776961: return $r('app.string.pen_palette_color_blue');
      case -8388480: return $r('app.string.pen_palette_color_purple');
      case -16181: return $r('app.string.pen_swatch_color_pink');
      case -10011977: return $r('app.string.pen_palette_color_brown_sugar');
      case -1: return $r('app.string.pen_palette_color_white');
      default: return null;
    }
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // 原版 spen_setting_swatch_1..23 色板包（各 8 色）+ adaptive 深色变体
  // （Phase 807）：dark 主题下 pack 有自适应变体时取用变体色。
  private isDarkMode(): boolean {
    const mode: string = this.themeMode;
    if (mode === 'system') {
      return this.systemDark;
    }
    return mode === 'dark';
  }

  private palettePackColors(index: number): number[] {
    if (this.isDarkMode()) {
      const adaptive: number[] | null = PEN_PALETTE_PACKS_ADAPTIVE[index];
      if (adaptive !== null) {
        return adaptive;
      }
    }
    return PEN_PALETTE_PACKS[index];
  }

  // 原版 ui_tools__color_hex（"Color #%1$s"）：无命名色的通用 a11y 标签。
  private hexA11yLabel(color: number): Resource {
    return $r('app.string.pen_string_color_hex',
      this.viewModel.colorToHex(color).substring(1));
  }

  private isActiveColor(color: number): boolean {
    return color === (this.selectionMode ? this.selectionColor : this.viewModel.brushColor);
  }

  private onWellColor(color: number, index: number): void {
    if (this.photoImportLeaseActive) {
      return;
    }
    this.viewModel.setBrushColor(color, index);
  }

  private onFreeColor(color: number): void {
    if (this.photoImportLeaseActive) {
      return;
    }
    if (this.selectionMode) {
      this.onSelectionColor(color);
    } else {
      this.viewModel.setBrushColor(color);
    }
  }

  // Original well-edit affordance (ys2/dhb event fan-out): long-press surfaces
  // the color-options menu — writing the current color into the well mirrors
  // ah9 OnColorWellValueChange(wellIndex, newColor); delete mirrors bh9
  // OnDeleteColorClick(pb4 well) with tb4 trayIndex shift-down.
  @Builder
  private buildWellMenu(index: number): void {
    Menu() {
      MenuItem({ content: $r('app.string.well_set_current_color') })
        .onClick(() => {
          if (this.photoImportLeaseActive) {
            return;
          }
          this.viewModel.setFavoriteColorWell(index, this.viewModel.brushColor)
            .catch((e: Error) => {
              console.error(`set favorite color well failed: ${JSON.stringify(e)}`);
            });
        })
      MenuItem({ content: $r('app.string.delete') })
        .onClick(() => {
          if (this.photoImportLeaseActive) {
            return;
          }
          this.viewModel.removeFavoriteColorWell(index).catch((e: Error) => {
            console.error(`remove favorite color well failed: ${JSON.stringify(e)}`);
          });
        })
    }
  }

  @Builder
  private colorDot(color: number, onTap: () => void,
    a11yName: Resource | null = null): void {
    Column()
      .accessibilityText(a11yName === null ?
        $r('app.string.pen_string_color') : a11yName)
      .width(32)
      .height(32)
      .borderRadius(16)
      .backgroundColor(this.viewModel.colorToHex(color))
      .border({
        width: this.isActiveColor(color) ? 3 : 1,
        color: this.isActiveColor(color) ? this.resolveTokens().accent : this.resolveTokens().border,
      })
      .enabled(!this.photoImportLeaseActive)
      .onClick(onTap)
  }

  build() {
    Column() {
      // 原版 r22 case9（ADR-0646）：色彩面板的 eyedropper 入口——开启后画布
      // 触摸转为取样（lu7.a enabled），提交颜色后自动关；选区模式下作用于
      // 选区颜色（lu7.b 的目标上下文）。
      Row() {
        Text($r('app.string.eyedropper'))
          .fontSize(13)
          .fontColor(this.viewModel.eyedropperActive
            ? this.resolveTokens().accent : this.resolveTokens().textPrimary)
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .border({
        width: 1,
        color: this.viewModel.eyedropperActive
          ? this.resolveTokens().accent : this.resolveTokens().border,
      })
      .enabled(!this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.setEyedropperActive(
          !this.viewModel.eyedropperActive, this.selectionMode);
      })
      .margin({ bottom: 12 })
      if (!this.selectionMode) {
        Grid() {
          ForEach(this.viewModel.favoriteColors, (color: number, index: number) => {
            GridItem() {
              // Original xg9/bh9/ah9 parity: tap selects (yg9), long-press opens
              // the well context menu (write current color / delete), and the
              // trailing '+' tile appends a well seeded with the brush color.
              Column() {
                this.colorDot(color, (): void => this.onWellColor(color, index))
              }
              .bindContextMenu(this.buildWellMenu(index), ResponseType.LongPress)
            }
          }, (color: number, index: number) => index.toString() + ':' + color.toString())
          GridItem() {
            Column() {
              Text('+')
                .fontSize(18)
                .fontColor(this.resolveTokens().textSecondary)
            }
            .width(32)
            .height(32)
            .borderRadius(16)
            .border({ width: 1, color: this.resolveTokens().border, style: BorderStyle.Dashed })
            .justifyContent(FlexAlign.Center)
            .enabled(!this.photoImportLeaseActive)
            .accessibilityText($r('app.string.add_a_color'))
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.viewModel.addFavoriteColorWell().catch((e: Error) => {
                console.error(`add favorite color well failed: ${JSON.stringify(e)}`);
              });
            })
          }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width(200)
        .margin({ bottom: 12 })
        if (this.viewModel.recentColors.length > 0) {
          Row() {
            ForEach(this.viewModel.recentColors, (color: number) => {
              this.colorDot(color, (): void => this.onFreeColor(color),
              this.presetColorName(color))
            }, (color: number) => 'recent:' + color.toString())
          }
          .width(200)
          .margin({ bottom: 12 })
        }
      }
      Grid() {
        ForEach(this.presetColors, (color: number) => {
          GridItem() {
            this.colorDot(color, (): void => this.onFreeColor(color),
              this.presetColorName(color))
          }
        }, (color: number) => 'preset:' + color.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width(200)
      .height(180)
      // 原版 spen_setting_swatch_* 主题色板库（Phase 807）：23 包各 8 色，
      // Swiper 分页浏览，点选即写入笔色——与原版色板浏览语义一致。
      Row() {
        Text($r('app.string.pen_string_palette_library'))
          .fontSize(11)
          .fontColor(this.resolveTokens().textSecondary)
      }
      .width(200)
      .margin({ top: 4 })
      .accessibilityText($r('app.string.pen_string_palette_library'))

      Swiper() {
        ForEach(PEN_PALETTE_PACKS.map((_p: number[], i: number) => i),
          (packIndex: number) => {
            Grid() {
              ForEach(this.palettePackColors(packIndex), (color: number) => {
                GridItem() {
                  this.colorDot(color, (): void => this.onFreeColor(color),
                    this.hexA11yLabel(color))
                }
              }, (color: number) => 'pack' + packIndex + ':' + color.toString())
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width(200)
          }, (packIndex: number) => 'packPage:' + packIndex.toString())
      }
      .indicator(Indicator.dot()
        .itemWidth(4)
        .itemHeight(4)
        .selectedItemWidth(4)
        .selectedItemHeight(4)
        .color(this.resolveTokens().border)
        .selectedColor(this.resolveTokens().accent))
      .width(200)
      .height(108)
      .autoPlay(false)
      .loop(false)
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }
}
