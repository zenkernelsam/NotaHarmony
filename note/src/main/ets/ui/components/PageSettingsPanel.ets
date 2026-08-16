// T-037 页面设置面板（尺寸/模板/方向选择，bindPopup 承载）
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import {
  NoteBackgroundSettings, PageOrientation, PaperSize, PaperTemplate,
} from '../../core/model/NoteTypes';
import {
  defaultOriginalBackgroundInfo, ORIGINAL_PAPER_SPACING_INCHES, OriginalBackgroundInfo,
  OriginalPaperBackground, OriginalPaperLineType, originalPaperLineTypeFromTemplate,
  sameOriginalPaperBackground,
} from '../../core/model/OriginalPaperSettings';
import {
  originalDefaultNoteBackgroundSettings,
} from '../../core/model/PageBackgroundModel';
import {
  applyOriginalTemplatePickerSelection, isOriginalTemplatePickerSelection,
  OriginalTemplatePickerDraft, originalTemplatePickerDraft, originalTemplatePickerFavorite,
  stageOriginalTemplateCustomColor, stageOriginalTemplateLegacyPaper,
  stageOriginalTemplateOrientation, stageOriginalTemplateSize,
} from '../../core/model/OriginalTemplatePickerState';
import {
  ORIGINAL_LEGACY_PAPER_PICKER_INDICES, OriginalHsvColor, originalArgbCssColor,
  originalHsvFromArgb, originalLegacyPaperPickerSwatchArgb, originalOpaqueArgbFromHsv,
  originalPaperPickerPreviewColor, originalPaperPickerPreviewLineColor,
} from '../../core/model/OriginalPaperColor';
import { DatabaseManager } from '../../data/DatabaseManager';
import { OriginalPaperSettingsStore } from '../../data/OriginalPaperSettingsStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

const SIZE_OPTIONS: PaperSizeOption[] = [
  { size: PaperSize.A3, label: 'A3', dim: '297×420' },
  { size: PaperSize.A4, label: 'A4', dim: '210×297' },
  { size: PaperSize.A5, label: 'A5', dim: '148×210' },
  { size: PaperSize.A6, label: 'A6', dim: '105×148' },
  { size: PaperSize.A7, label: 'A7', dim: '74×105' },
  { size: PaperSize.LETTER, label: 'Letter', dim: '216×279' },
  { size: PaperSize.LEGAL, label: 'Legal', dim: '216×356' },
  { size: PaperSize.TABLOID, label: 'Tabloid', dim: '279×432' },
];

const TEMPLATE_OPTIONS: PaperTemplate[] = [
  PaperTemplate.PLAIN, PaperTemplate.LINES, PaperTemplate.GRID, PaperTemplate.DOTS,
];

interface PaperSizeOption {
  size: PaperSize;
  label: string;
  dim: string;
}

@Component
export struct PageSettingsPanel {
  @Prop @Watch('onSettingsChange') settings: NoteBackgroundSettings =
    originalDefaultNoteBackgroundSettings();
  @Prop busy: boolean = false;
  @State draft: OriginalTemplatePickerDraft = {
    size: PaperSize.LETTER,
    orientation: PageOrientation.PORTRAIT,
    backgroundColor: -1,
    legacyPaperIndex: null,
  };
  @State customColorExpanded: boolean = false;
  @State customHue: number = 0;
  @State customSaturation: number = 0;
  @State customValue: number = 100;
  @State backgroundInfos: OriginalBackgroundInfo[] = [
    defaultOriginalBackgroundInfo(OriginalPaperLineType.PLAIN),
    defaultOriginalBackgroundInfo(OriginalPaperLineType.LINES),
    defaultOriginalBackgroundInfo(OriginalPaperLineType.GRID),
    defaultOriginalBackgroundInfo(OriginalPaperLineType.DOTS),
  ];
  @State favorites: OriginalPaperBackground[] = [];
  @State sharedBusy: boolean = false;
  @State sharedLoadFailed: boolean = false;
  @State spacingTemplate: PaperTemplate | null = null;
  @State spacingPreviewIndex: number = -1;
  @State spacingSaveBusy: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onApply: (settings: NoteBackgroundSettings) => void = () => {
  };

  private paperStore: OriginalPaperSettingsStore | null = null;
  private sharedLoadGeneration: number = 0;

  aboutToAppear(): void {
    this.resetDraft();
    this.reloadSharedPaperSettings();
  }

  aboutToDisappear(): void {
    this.sharedLoadGeneration++;
  }

  private onSettingsChange(): void {
    this.resetDraft();
  }

  private resetDraft(): void {
    this.draft = originalTemplatePickerDraft(this.settings);
    this.customColorExpanded = false;
    this.resetCustomColorControls();
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private isDarkMode(): boolean {
    return this.themeMode === 'dark' || (this.themeMode === 'system' && this.systemDark);
  }

  private resetCustomColorControls(): void {
    let source: number | null = this.draft.backgroundColor;
    if (source === null && this.draft.legacyPaperIndex !== null) {
      source = originalLegacyPaperPickerSwatchArgb(this.draft.legacyPaperIndex);
    }
    const hsv: OriginalHsvColor = originalHsvFromArgb(source === null ? -1 : source);
    this.customHue = hsv.hue;
    this.customSaturation = hsv.saturation * 100;
    this.customValue = hsv.value * 100;
  }

  private selectLegacyPaper(legacyPaperIndex: number): void {
    if (this.busy || this.sharedBusy || this.spacingSaveBusy) {
      return;
    }
    this.draft = stageOriginalTemplateLegacyPaper(this.draft, legacyPaperIndex);
    const swatch: number | null = originalLegacyPaperPickerSwatchArgb(legacyPaperIndex);
    if (swatch !== null) {
      const hsv: OriginalHsvColor = originalHsvFromArgb(swatch);
      this.customHue = hsv.hue;
      this.customSaturation = hsv.saturation * 100;
      this.customValue = hsv.value * 100;
    }
  }

  private activateCustomColor(): void {
    if (this.busy || this.sharedBusy || this.spacingSaveBusy) {
      return;
    }
    this.customColorExpanded = true;
    // Opening the no-alpha HSV controls must not rewrite an existing ARGB value.
    // Only switching from legacy/no-color, or an actual slider edit, writes opaque.
    if (this.draft.backgroundColor === null) {
      this.stageCustomColor();
    }
  }

  private stageCustomColor(): void {
    const color: number = originalOpaqueArgbFromHsv(
      this.customHue, this.customSaturation / 100, this.customValue / 100);
    this.draft = stageOriginalTemplateCustomColor(this.draft, color);
  }

  private updateCustomHue(value: number): void {
    this.customHue = Math.max(0, Math.min(360, value));
    this.stageCustomColor();
  }

  private updateCustomSaturation(value: number): void {
    this.customSaturation = Math.max(0, Math.min(100, value));
    this.stageCustomColor();
  }

  private updateCustomValue(value: number): void {
    this.customValue = Math.max(0, Math.min(100, value));
    this.stageCustomColor();
  }

  private customColorCss(): string {
    if (this.draft.backgroundColor !== null) {
      return originalArgbCssColor(this.draft.backgroundColor);
    }
    return originalArgbCssColor(originalOpaqueArgbFromHsv(
      this.customHue, this.customSaturation / 100, this.customValue / 100));
  }

  private templatePreviewBackground(): string {
    return originalPaperPickerPreviewColor(this.draft.backgroundColor,
      this.draft.legacyPaperIndex, this.resolveTokens().paperBackground, this.isDarkMode());
  }

  private templatePreviewLineColor(): string {
    return originalPaperPickerPreviewLineColor(this.draft.backgroundColor,
      this.draft.legacyPaperIndex, this.resolveTokens().paperLineColor, this.isDarkMode());
  }

  private async reloadSharedPaperSettings(): Promise<void> {
    const generation: number = ++this.sharedLoadGeneration;
    this.sharedBusy = true;
    this.sharedLoadFailed = false;
    try {
      const database: DatabaseManager = DatabaseManager.getInstance();
      await database.initialize(getContext(this) as common.UIAbilityContext);
      const store: OriginalPaperSettingsStore = new OriginalPaperSettingsStore(database);
      const infos: OriginalBackgroundInfo[] = await store.listBackgroundInfos();
      const favorites: OriginalPaperBackground[] = await store.listFavorites();
      if (generation !== this.sharedLoadGeneration) {
        return;
      }
      this.paperStore = store;
      this.backgroundInfos = infos;
      this.favorites = favorites;
      this.spacingPreviewIndex = -1;
    } catch (error) {
      if (generation !== this.sharedLoadGeneration) {
        return;
      }
      this.paperStore = null;
      this.sharedLoadFailed = true;
      this.spacingPreviewIndex = -1;
      console.error(`PageSettingsPanel shared paper settings load failed: ${JSON.stringify(error)}`);
    } finally {
      if (generation === this.sharedLoadGeneration) {
        this.sharedBusy = false;
      }
    }
  }

  private storedBackgroundInfoForTemplate(template: PaperTemplate): OriginalBackgroundInfo {
    const paperLineType: OriginalPaperLineType = originalPaperLineTypeFromTemplate(template);
    for (const info of this.backgroundInfos) {
      if (info.paperLineType === paperLineType) {
        return info;
      }
    }
    return defaultOriginalBackgroundInfo(paperLineType);
  }

  private backgroundInfoForTemplate(template: PaperTemplate): OriginalBackgroundInfo {
    const stored: OriginalBackgroundInfo = this.storedBackgroundInfoForTemplate(template);
    if (template === PaperTemplate.PLAIN || this.spacingTemplate !== template ||
      this.spacingPreviewIndex < 0 ||
      this.spacingPreviewIndex >= ORIGINAL_PAPER_SPACING_INCHES.length) {
      return stored;
    }
    return {
      paperLineType: stored.paperLineType,
      spacingInches: ORIGINAL_PAPER_SPACING_INCHES[this.spacingPreviewIndex],
      hasOptions: stored.hasOptions,
    };
  }

  private isTemplateSelected(template: PaperTemplate): boolean {
    return isOriginalTemplatePickerSelection(
      this.settings, this.draft, template, this.backgroundInfoForTemplate(template));
  }

  private favoriteCandidate(template: PaperTemplate): OriginalPaperBackground {
    return originalTemplatePickerFavorite(
      this.settings, this.draft, this.backgroundInfoForTemplate(template));
  }

  private isTemplateFavorite(template: PaperTemplate): boolean {
    const candidate: OriginalPaperBackground = this.favoriteCandidate(template);
    for (const favorite of this.favorites) {
      if (sameOriginalPaperBackground(favorite, candidate)) {
        return true;
      }
    }
    return false;
  }

  private applyTemplate(template: PaperTemplate): void {
    if (this.busy || this.sharedBusy || this.spacingSaveBusy) {
      return;
    }
    this.onApply(applyOriginalTemplatePickerSelection(
      this.settings, this.draft, template, this.backgroundInfoForTemplate(template)));
  }

  private async toggleFavorite(template: PaperTemplate): Promise<void> {
    const store: OriginalPaperSettingsStore | null = this.paperStore;
    if (store === null || this.busy || this.sharedBusy || this.spacingSaveBusy) {
      return;
    }
    const candidate: OriginalPaperBackground = this.favoriteCandidate(template);
    const remove: boolean = this.isTemplateFavorite(template);
    this.sharedBusy = true;
    try {
      if (remove) {
        await store.removeFavorite(candidate);
      } else {
        await store.addFavorite(candidate);
      }
      this.favorites = await store.listFavorites();
    } catch (error) {
      console.error(`PageSettingsPanel favorite update failed: ${JSON.stringify(error)}`);
      this.showSharedPaperFailure();
    } finally {
      this.sharedBusy = false;
    }
  }

  private spacingIndex(template: PaperTemplate): number {
    if (this.spacingTemplate === template && this.spacingPreviewIndex >= 0 &&
      this.spacingPreviewIndex < ORIGINAL_PAPER_SPACING_INCHES.length) {
      return this.spacingPreviewIndex;
    }
    return this.storedSpacingIndex(template);
  }

  private storedSpacingIndex(template: PaperTemplate): number {
    const spacing: number | null = this.storedBackgroundInfoForTemplate(template).spacingInches;
    if (spacing === null) {
      return 3;
    }
    const index: number = ORIGINAL_PAPER_SPACING_INCHES.indexOf(spacing);
    return index < 0 ? 3 : index;
  }

  private toggleSpacingSettings(template: PaperTemplate): void {
    if (this.busy || this.sharedBusy || this.spacingSaveBusy || this.paperStore === null) {
      return;
    }
    if (this.spacingTemplate === template) {
      this.spacingTemplate = null;
      this.spacingPreviewIndex = -1;
      return;
    }
    this.spacingTemplate = template;
    this.spacingPreviewIndex = this.storedSpacingIndex(template);
  }

  private previewSharedSpacing(template: PaperTemplate, rawIndex: number,
    mode: SliderChangeMode): void {
    if (this.paperStore === null || this.busy || this.sharedBusy || this.spacingSaveBusy ||
      this.spacingTemplate !== template || template === PaperTemplate.PLAIN) {
      return;
    }
    const index: number = Math.max(0, Math.min(
      ORIGINAL_PAPER_SPACING_INCHES.length - 1, Math.round(rawIndex)));
    this.spacingPreviewIndex = index;
    // ArkUI emits Begin/Moving repeatedly while dragging. Persist only the final End/Click
    // value so the original continuous preview cannot lose its last position behind an async write.
    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
      this.saveSharedSpacing(template, index);
    }
  }

  private async saveSharedSpacing(template: PaperTemplate, rawIndex: number): Promise<void> {
    const store: OriginalPaperSettingsStore | null = this.paperStore;
    if (store === null || this.busy || this.sharedBusy || this.spacingSaveBusy ||
      template === PaperTemplate.PLAIN) {
      return;
    }
    const index: number = Math.max(0, Math.min(
      ORIGINAL_PAPER_SPACING_INCHES.length - 1, Math.round(rawIndex)));
    if (index === this.storedSpacingIndex(template)) {
      return;
    }
    const storedInfo: OriginalBackgroundInfo = this.storedBackgroundInfoForTemplate(template);
    const optimistic: OriginalBackgroundInfo = {
      paperLineType: originalPaperLineTypeFromTemplate(template),
      spacingInches: ORIGINAL_PAPER_SPACING_INCHES[index],
      hasOptions: storedInfo.hasOptions,
    };
    this.spacingSaveBusy = true;
    try {
      const saved: OriginalBackgroundInfo = await store.saveSpacing(
        optimistic.paperLineType, optimistic.spacingInches as number);
      this.replaceBackgroundInfo(saved);
      if (this.spacingTemplate === template) {
        const savedIndex: number = saved.spacingInches === null ? -1 :
          ORIGINAL_PAPER_SPACING_INCHES.indexOf(saved.spacingInches);
        this.spacingPreviewIndex = savedIndex < 0 ? this.storedSpacingIndex(template) : savedIndex;
      }
    } catch (error) {
      if (this.spacingTemplate === template) {
        this.spacingPreviewIndex = this.storedSpacingIndex(template);
      }
      console.error(`PageSettingsPanel spacing update failed: ${JSON.stringify(error)}`);
      this.showSharedPaperFailure();
    } finally {
      this.spacingSaveBusy = false;
    }
  }

  private replaceBackgroundInfo(value: OriginalBackgroundInfo): void {
    const next: OriginalBackgroundInfo[] = [];
    let replaced: boolean = false;
    for (const info of this.backgroundInfos) {
      if (info.paperLineType === value.paperLineType) {
        next.push(value);
        replaced = true;
      } else {
        next.push(info);
      }
    }
    if (!replaced) {
      next.push(value);
    }
    this.backgroundInfos = next;
  }

  private showSharedPaperFailure(): void {
    try {
      promptAction.showToast({ message: $r('app.string.paper_settings_save_failed') });
    } catch (_toastError) {
    }
  }

  build() {
    Column() {
      // === 尺寸 ===
      Text($r('app.string.paper_size')).fontSize(14).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
      Grid() {
        ForEach(SIZE_OPTIONS, (opt: PaperSizeOption) => {
          GridItem() {
            Column() {
              Text(opt.label).fontSize(13)
              Text(opt.dim).fontSize(10).fontColor(this.resolveTokens().textSecondary)
            }
            .width(76)
            .height(52)
            .justifyContent(FlexAlign.Center)
            .borderRadius(8)
            .backgroundColor(opt.size === this.draft.size ? this.resolveTokens().accent :
              this.resolveTokens().control)
            .border({ width: 1, color: opt.size === this.draft.size ? this.resolveTokens().accent :
              this.resolveTokens().border })
            .onClick(() => {
              if (!this.busy && !this.sharedBusy && !this.spacingSaveBusy) {
                this.draft = stageOriginalTemplateSize(this.draft, opt.size);
              }
            })
          }
        }, (opt: PaperSizeOption) => opt.size.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width(340)
      .height(130)

      // === 原版纸色：六个 legacy swatch + 无 alpha 的 HSV 自定义色 ===
      Text($r('app.string.paper_color')).fontSize(14).fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
      Row() {
        ForEach(ORIGINAL_LEGACY_PAPER_PICKER_INDICES, (legacyPaperIndex: number) => {
          Column() {
            Column()
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor(originalArgbCssColor(
                originalLegacyPaperPickerSwatchArgb(legacyPaperIndex) as number))
              .border({
                width: this.draft.backgroundColor === null &&
                  this.draft.legacyPaperIndex === legacyPaperIndex ? 3 : 1,
                color: this.draft.backgroundColor === null &&
                  this.draft.legacyPaperIndex === legacyPaperIndex ?
                  this.resolveTokens().accent : this.resolveTokens().border,
              })
              .onClick(() => {
                this.selectLegacyPaper(legacyPaperIndex);
              })
            Text(this.legacyPaperLabel(legacyPaperIndex))
              .fontSize(9)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ top: 3 })
          }
          .width(52)
        }, (legacyPaperIndex: number) => legacyPaperIndex.toString())
      }
      .width(340)
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Column()
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor(this.customColorCss())
          .border({ width: 1, color: this.resolveTokens().border })
        Button($r('app.string.paper_custom_color'))
          .height(34)
          .fontSize(12)
          .margin({ left: 8 })
          .backgroundColor(this.draft.backgroundColor !== null ?
            this.resolveTokens().accent : this.resolveTokens().control)
          .fontColor(this.draft.backgroundColor !== null ?
            this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
          .enabled(!this.busy && !this.sharedBusy && !this.spacingSaveBusy)
          .onClick(() => {
            this.activateCustomColor();
          })
        Blank()
        if (this.customColorExpanded) {
          Button('×')
            .width(30)
            .height(28)
            .fontSize(16)
            .padding(0)
            .backgroundColor(this.resolveTokens().control)
            .accessibilityText($r('app.string.paper_custom_color_close'))
            .onClick(() => {
              this.customColorExpanded = false;
            })
        }
      }
      .width(340)
      .margin({ top: 8 })

      if (this.customColorExpanded) {
        Column() {
          Text($r('app.string.paper_color_hue', Math.round(this.customHue)))
            .width('100%').fontSize(10).fontColor(this.resolveTokens().textSecondary)
          Slider({ value: this.customHue, min: 0, max: 360, step: 1 })
            .width('100%')
            .selectedColor(this.resolveTokens().accent)
            .onChange((value: number, _mode: SliderChangeMode) => {
              this.updateCustomHue(value);
            })
          Text($r('app.string.paper_color_saturation', Math.round(this.customSaturation)))
            .width('100%').fontSize(10).fontColor(this.resolveTokens().textSecondary)
          Slider({ value: this.customSaturation, min: 0, max: 100, step: 1 })
            .width('100%')
            .selectedColor(this.resolveTokens().accent)
            .onChange((value: number, _mode: SliderChangeMode) => {
              this.updateCustomSaturation(value);
            })
          Text($r('app.string.paper_color_value', Math.round(this.customValue)))
            .width('100%').fontSize(10).fontColor(this.resolveTokens().textSecondary)
          Slider({ value: this.customValue, min: 0, max: 100, step: 1 })
            .width('100%')
            .selectedColor(this.resolveTokens().accent)
            .onChange((value: number, _mode: SliderChangeMode) => {
              this.updateCustomValue(value);
            })
          Text($r('app.string.paper_color_opaque_hint'))
            .width('100%')
            .fontSize(9)
            .fontColor(this.resolveTokens().textSecondary)
        }
        .width(340)
        .padding(10)
        .margin({ top: 8 })
        .backgroundColor(this.resolveTokens().control)
        .borderRadius(8)
      }

      // === 模板（自绘迷你预览：展示类，无原生等价物）===
      Text($r('app.string.paper_template')).fontSize(14).fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
      Text($r('app.string.template_pick_hint'))
        .fontSize(11)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ bottom: 8 })
      Row() {
        ForEach(TEMPLATE_OPTIONS, (tpl: PaperTemplate) => {
            Column() {
              Stack() {
                Column() {
                  this.TemplatePreview(tpl)
                }
                .onClick(() => {
                  this.applyTemplate(tpl);
                })
                Button(this.isTemplateFavorite(tpl) ? '★' : '☆')
                  .width(28)
                  .height(28)
                  .fontSize(18)
                  .padding(0)
                  .align(Alignment.TopEnd)
                  .backgroundColor(this.resolveTokens().control)
                  .fontColor(this.isTemplateFavorite(tpl) ? this.resolveTokens().accent :
                    this.resolveTokens().textSecondary)
                  .enabled(!this.busy && !this.sharedBusy && !this.spacingSaveBusy &&
                    this.paperStore !== null)
                  .accessibilityText(this.isTemplateFavorite(tpl) ?
                    $r('app.string.template_unfavorite') : $r('app.string.template_favorite'))
                  .onClick(() => {
                    this.toggleFavorite(tpl);
                  })
              }
              .width(68)
              .height(78)
              Text(this.templateLabel(tpl)).fontSize(10).margin({ top: 4 })
              if (tpl !== PaperTemplate.PLAIN &&
                this.backgroundInfoForTemplate(tpl).hasOptions) {
                Button('⋯')
                  .width(36)
                  .height(24)
                  .fontSize(16)
                  .padding(0)
                  .margin({ top: 2 })
                  .backgroundColor(this.spacingTemplate === tpl ? this.resolveTokens().accent :
                    this.resolveTokens().control)
                  .fontColor(this.spacingTemplate === tpl ? this.resolveTokens().onAccent :
                    this.resolveTokens().textPrimary)
                  .enabled(!this.busy && !this.sharedBusy && !this.spacingSaveBusy &&
                    this.paperStore !== null)
                  .accessibilityText($r('app.string.template_settings'))
                  .onClick(() => {
                    this.toggleSpacingSettings(tpl);
                  })
              }
            }
            .width(76)
          }, (tpl: PaperTemplate) => tpl.toString())
      }
      .width(340)
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.sharedBusy && this.paperStore === null) {
        Row() {
          LoadingProgress().width(18).height(18)
          Text($r('app.string.paper_settings_loading'))
            .fontSize(11)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ left: 6 })
        }
        .margin({ top: 8 })
      } else if (this.sharedLoadFailed) {
        Row() {
          Text($r('app.string.paper_settings_load_failed'))
            .fontSize(11)
            .fontColor(this.resolveTokens().danger)
          Blank()
          Button($r('app.string.retry'))
            .height(30)
            .fontSize(11)
            .onClick(() => {
              this.reloadSharedPaperSettings();
            })
        }
        .width(340)
        .margin({ top: 8 })
      }

      if (this.spacingTemplate !== null) {
        this.SpacingSettings(this.spacingTemplate as PaperTemplate)
      }

      // === 方向 ===
      Text($r('app.string.page_orientation')).fontSize(14).fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
      Row() {
        Button($r('app.string.portrait'))
          .height(36)
          .fontSize(13)
          .margin({ right: 8 })
          .backgroundColor(this.draft.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.draft.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            if (!this.busy && !this.sharedBusy && !this.spacingSaveBusy &&
              this.draft.orientation !== PageOrientation.PORTRAIT) {
              this.draft = stageOriginalTemplateOrientation(
                this.draft, PageOrientation.PORTRAIT);
            }
          })
        Button($r('app.string.landscape'))
          .height(36)
          .fontSize(13)
          .backgroundColor(this.draft.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.draft.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            if (!this.busy && !this.sharedBusy && !this.spacingSaveBusy &&
              this.draft.orientation !== PageOrientation.LANDSCAPE) {
              this.draft = stageOriginalTemplateOrientation(
                this.draft, PageOrientation.LANDSCAPE);
            }
          })
      }
    }
    .padding(16)
    .width('100%')
    .constraintSize({ minWidth: 320, maxWidth: 420 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .enabled(!this.busy)
    .opacity(this.busy ? 0.6 : 1)
  }

  @Builder
  SpacingSettings(template: PaperTemplate) {
    Column() {
      Row() {
        Text($r('app.string.template_settings'))
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
        Blank()
        Button('×')
          .width(30)
          .height(28)
          .fontSize(16)
          .padding(0)
          .backgroundColor(this.resolveTokens().control)
          .enabled(!this.spacingSaveBusy)
          .accessibilityText($r('app.string.close_template_settings'))
          .onClick(() => {
            if (!this.spacingSaveBusy) {
              this.spacingTemplate = null;
              this.spacingPreviewIndex = -1;
            }
          })
      }
      .width('100%')
      Text($r('app.string.template_spacing_level', this.spacingIndex(template) + 1))
        .width('100%')
        .fontSize(11)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 4, bottom: 4 })
      Slider({
        value: this.spacingIndex(template),
        min: 0,
        max: ORIGINAL_PAPER_SPACING_INCHES.length - 1,
        step: 1,
      })
        .width('100%')
        .enabled(!this.busy && !this.sharedBusy && !this.spacingSaveBusy &&
          this.paperStore !== null)
        .selectedColor(this.resolveTokens().accent)
        .onChange((value: number, mode: SliderChangeMode) => {
          this.previewSharedSpacing(template, value, mode);
        })
    }
    .width(340)
    .padding(10)
    .margin({ top: 10 })
    .backgroundColor(this.resolveTokens().control)
    .border({ width: 1, color: this.resolveTokens().border })
    .borderRadius(8)
  }

  // 模板迷你预览（自绘：白色底 + 线/点模拟）
  @Builder
  TemplatePreview(tpl: PaperTemplate) {
    Stack() {
      Column()
        .width(60)
        .height(78)
        .backgroundColor(this.templatePreviewBackground())
        .border({ width: this.isTemplateSelected(tpl) ? 2 : 1,
          color: this.isTemplateSelected(tpl) ?
            this.resolveTokens().accent : this.resolveTokens().border })
        .borderRadius(4)
      if (tpl === PaperTemplate.LINES) {
        Column() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            Divider().color(this.templatePreviewLineColor()).strokeWidth(1).margin({ top: 12 })
          }, (_i: number) => _i.toString())
        }
        .width(48)
        .height(66)
        .justifyContent(FlexAlign.Center)
      } else if (tpl === PaperTemplate.GRID) {
        Grid() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            GridItem() {
              Column().width(8).height(8).backgroundColor(this.templatePreviewLineColor())
            }
          }, (_i: number) => _i.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width(48)
        .height(48)
        .columnsGap(6)
        .rowsGap(6)
        .margin({ top: 10 })
      } else if (tpl === PaperTemplate.DOTS) {
        Grid() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            GridItem() {
              Column().width(5).height(5).borderRadius(3).backgroundColor(this.templatePreviewLineColor())
            }
          }, (_i: number) => _i.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width(48)
        .height(48)
        .columnsGap(8)
        .rowsGap(8)
        .margin({ top: 10 })
      }
    }
    .width(60)
    .height(78)
  }

  private templateLabel(tpl: PaperTemplate): ResourceStr {
    switch (tpl) {
      case PaperTemplate.PLAIN:
        return $r('app.string.template_plain');
      case PaperTemplate.LINES:
        return $r('app.string.template_lines');
      case PaperTemplate.GRID:
        return $r('app.string.template_grid');
      case PaperTemplate.DOTS:
        return $r('app.string.template_dots');
      default:
        return '';
    }
  }

  private legacyPaperLabel(legacyPaperIndex: number): ResourceStr {
    switch (legacyPaperIndex) {
      case 13:
        return $r('app.string.paper_legacy_white');
      case 1:
        return $r('app.string.paper_legacy_cream');
      case 2:
        return $r('app.string.paper_legacy_yellow');
      case 15:
        return $r('app.string.paper_legacy_black');
      case 7:
        return $r('app.string.paper_legacy_blue');
      case 6:
        return $r('app.string.paper_legacy_tan');
      default:
        return '';
    }
  }
}
