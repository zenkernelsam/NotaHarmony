// Phase 1405 — 原版笔记封面预设选择器（ebn.java / l7b / i7b / d7b 等价）。
// 原版证据（decompiled_1.4.2）：
//   iw2：10 个 CoverPreset{F=covers/<key>.pdf, G=drawable 预览, H=名字 res,
//     I=类目文案}；rs case6 预摘要 SHA-512。
//   ebn.b：标题 "Note cover preview" + 预览卡（封面图 + noteTitle +
//     noteDateText，a(...) 库卡片形态）+ "Presets" 区 + g8n.a 底栏
//     Cancel/Done（c85 lambda）；候选 gw2 = NoSelection/Preset(iw2)/
//     Custom(jwf 上传图——fail-closed)。
//   d7b.b：Done → covers/<F>.pdf 导入 CAS → 替换封面元素媒体；
//     note 不可用 → "Cover change skipped" 日志短路。
//   入口：cbn.f content manager 页菜单 "Add Note Cover"（z5&&z4 门控，
//     位于 create_template 与 clear_page 之间）。
// Harmony 子集（ADR-1341）：preset 选择 + 预览卡 + Cancel/Done；
//   持久化为 note_meta.cover_preset preset 键；库卡片渲染封面 PDF 首页。
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import {
  NOTE_COVER_PRESETS, NoteCoverPreset, loadNoteCoverThumb,
} from '../../core/model/NoteCoverCatalog';
import { DatabaseManager } from '../../data/DatabaseManager';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';

@Component
export struct NoteCoverSheet {
  @StorageProp(THEME_MODE_KEY) private themeMode: string = 'system';
  @StorageProp(THEME_SYSTEM_DARK_KEY) private systemDark: boolean = false;
  database: DatabaseManager = DatabaseManager.getInstance();
  noteTitle: string = '';
  noteCreatedAt: number = 0;
  // 原版 ebn.c 第三参 jwf → ew2 种子；Harmony preset 面以 cover_preset 键
  // 反查 fw2 等价预选（非 preset 值 → 无预选）。
  currentPresetKey: string | null = null;
  busy: boolean = false;
  onApply: (presetKey: string) => void = (_presetKey: string) => {};
  onRequestClose: () => void = () => {};
  @State private selectedKey: string = '';
  @State private thumbMap: Map<string, PixelMap> = new Map<string, PixelMap>();
  private thumbLoaded: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private coverDateText(): string {
    // 原版 i7b.c = noteDateText —— 预览卡上的笔记日期行。
    if (this.noteCreatedAt <= 0) {
      return '';
    }
    const date: Date = new Date(this.noteCreatedAt);
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private async loadThumbs(): Promise<void> {
    if (this.thumbLoaded) {
      return;
    }
    this.thumbLoaded = true;
    const context: common.UIAbilityContext =
      getContext(this) as common.UIAbilityContext;
    const next: Map<string, PixelMap> = new Map<string, PixelMap>();
    for (const preset of NOTE_COVER_PRESETS) {
      const pixelMap: image.PixelMap | null = await loadNoteCoverThumb(
        context, this.database, preset);
      if (pixelMap !== null) {
        next.set(preset.key, pixelMap);
      }
    }
    for (const stale of this.thumbMap.values()) {
      try {
        await stale.release();
      } catch (_e) {
      }
    }
    this.thumbMap = next;
  }

  aboutToAppear(): void {
    this.selectedKey = this.currentPresetKey === null ? '' : this.currentPresetKey;
    this.loadThumbs();
  }

  aboutToDisappear(): void {
    const released: Map<string, PixelMap> = this.thumbMap;
    this.thumbMap = new Map<string, PixelMap>();
    released.forEach((pixelMap: PixelMap): void => {
      pixelMap.release().catch((): void => {});
    });
  }

  @Builder
  private previewCard() {
    Column() {
      Stack() {
        if (this.thumbMap.get(this.selectedKey) !== undefined) {
          Image(this.thumbMap.get(this.selectedKey))
            .width('100%')
            .height(180)
            .objectFit(ImageFit.Cover)
        } else {
          Column()
            .width('100%')
            .height(180)
            .backgroundColor(this.resolveTokens().control)
        }
      }
      .width('100%')
      .clip(true)
      Text(this.noteTitle)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 10 })
      Text(this.coverDateText())
        .fontSize(12)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 2 })
    }
    .width(160)
    .padding(12)
    .borderRadius(12)
    .backgroundColor(this.resolveTokens().surface)
  }

  build() {
    Column() {
      Row() {
        // 原版 ebn.b 标题 ui_notecovers__title。
        Text($r('app.string.note_cover_title'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
          .layoutWeight(1)
        Button() {
          ToolGlyph({
            glyph: 'close_med_regular',
            contentColor: this.resolveTokens().textSecondary,
            iconSize: 20,
          })
        }
          .width(36)
          .height(32)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.cd_pages_panel_close'))
          .onClick((): void => this.onRequestClose())
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 12, bottom: 8 })

      Column() {
        this.previewCard()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 12 })

      Text($r('app.string.note_cover_presets'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textSecondary)
        .width('100%')
        .margin({ left: 16, bottom: 8 })

      Scroll() {
        Grid() {
          ForEach(NOTE_COVER_PRESETS, (preset: NoteCoverPreset) => {
            GridItem() {
              Column() {
                Stack() {
                  if (this.thumbMap.get(preset.key) !== undefined) {
                    Image(this.thumbMap.get(preset.key))
                      .width('100%')
                      .height(110)
                      .objectFit(ImageFit.Cover)
                  } else {
                    Column()
                      .width('100%')
                      .height(110)
                      .backgroundColor(this.resolveTokens().control)
                  }
                  if (this.selectedKey === preset.key) {
                    Column()
                      .width('100%')
                      .height(110)
                      .border({ width: 2, color: this.resolveTokens().accent })
                      .borderRadius(10)
                  }
                }
                .width('100%')
                .clip(true)
                .borderRadius(10)
                Text(preset.nameRes)
                  .fontSize(12)
                  .fontColor(this.resolveTokens().textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
              }
              .width('100%')
              .onClick((): void => {
                // 原版 selectPreset(iw2) → 候选 fw2；Done 才持久化。
                if (!this.busy) {
                  this.selectedKey = preset.key;
                }
              })
            }
          }, (preset: NoteCoverPreset): string => preset.key)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .layoutWeight(1)

      // 原版 g8n.a 底栏：Cancel / Done（Done 需有候选）。
      Row() {
        Button($r('app.string.cancel'))
          .fontSize(15)
          .fontColor(this.resolveTokens().textPrimary)
          .backgroundColor(this.resolveTokens().control)
          .layoutWeight(1)
          .onClick((): void => this.onRequestClose())
        Blank().width(12)
        Button($r('app.string.done'))
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(this.selectedKey === '' || this.busy
            ? this.resolveTokens().control : this.resolveTokens().accent)
          .enabled(this.selectedKey !== '' && !this.busy)
          .layoutWeight(1)
          .onClick((): void => {
            if (this.selectedKey !== '') {
              this.onApply(this.selectedKey);
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().surface)
  }
}
