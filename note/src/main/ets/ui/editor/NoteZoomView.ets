// Phase 747 — 原版 Zoom View 放大书写面板
// 证据：ggg(ZoomViewState：isShown/dockEdge/sourceRectDocPx/magnification=5.0/
// advanceRegionWidth=180dp/panelInTopHalf)、qeg(Top|Bottom 停靠枚举)、
// lgg(默认隐藏+底部停靠+5×+180dp)、wfg(控制条：拖拽柄+Back/Forward/Return/
// Close 四枚 48dp 按钮)、g0j(zoom_advance_tab 自动前进区)、
// ww2(default case 控制条布局顺序)、ufg(Advance/Back/Return 重定位事件)。
// 数据流：父组件持有 ggg 状态源（sourceRect/dockEdge/mag），本组件渲染
// 放大画布 + 控制条；触摸事件透传父组件，由父组件复用 StrokeSession 管线。

import { Canvas2DRenderContext } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

// Phase 752：原版 setAdvanceRegionWidth 夹取域 —— htd case 18
// rh8.u(value, 48.0f, 336.0f)（dp；Harmony 用 vp 等价）
const ZOOM_ADVANCE_WIDTH_MIN_VP: number = 48;
const ZOOM_ADVANCE_WIDTH_MAX_VP: number = 336;

@Component
export struct NoteZoomView {
  // ggg.a isShown 由父组件控制显隐；以下均为 ggg 状态字段投影。
  @Prop surfaceHeightVp: number = 160;
  // ggg.c sourceRectDocPx 左上原点（doc px，文档坐标=页面 pt）
  @Prop @Watch('repaint') sourceX: number = 0;
  @Prop @Watch('repaint') sourceY: number = 0;
  // ggg.d magnification = 5.0f（screen px / doc px）
  @Prop @Watch('repaint') magnification: number = 5;
  // ggg.e advanceRegionWidth = 180dp（Harmony 用 vp 近似）
  @Prop @Watch('repaint') advanceWidthVp: number = 180;
  // ggg.b dockEdge：qeg.J=Bottom（lgg 默认）/ qeg.I=Top
  @Prop dockBottom: boolean = true;
  // 父级每帧 ++ 驱动重绘（live stroke 进行中逐帧刷新）
  @Prop @Watch('repaint') paintTick: number = 0;
  @Prop panelEnabled: boolean = true;
  // Phase 748：原版 vgg 注入整页渲染栈——放大面绘制完整页面（纸面 +
  // z-order 全部元素 + 活动笔画）。父组件在已施加 mag 变换的上下文上
  // 按文档坐标直绘；renderZoom 传入 magnification 而非视口 zoom。
  renderContent: (renderContext: Canvas2DRenderContext,
    rawCtx: CanvasRenderingContext2D, mag: number) => void = () => {
  };

  // 触摸透传：父组件统一维护 StrokeSession 生命周期与坐标映射
  onZoomTouch: (event: TouchEvent) => void = () => {
  };
  onClose: () => void = () => {
  };
  onDockRequest: (bottom: boolean) => void = () => {
  };
  onStepBack: () => void = () => {
  };
  onStepForward: () => void = () => {
  };
  onReturnToInk: () => void = () => {
  };
  // g0j zoom_advance_tab 横向拖拽调整自动前进区宽（60..320vp 夹取）
  onAdvanceRegionResize: (widthVp: number) => void = () => {
  };
  // 拖拽提交点（onActionEnd）：原版 n27 case 2 经 tk8.g 持久化 o59.r；
  // Harmony 由父组件写 EditorSettingsStore（原版逐帧写库，此处每次拖拽
  // 提交写一次，跨会话可观察语义等价）。
  onAdvanceRegionCommit: (widthVp: number) => void = () => {
  };

  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private zoomCtx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private renderCtx: Canvas2DRenderContext = new Canvas2DRenderContext(this.zoomCtx);
  private advanceDragStartWidthVp: number = 180;
  private advanceDragLastWidthVp: number = 180;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private repaint(): void {
    this.draw();
  }

  private draw(): void {
    const ctx: CanvasRenderingContext2D = this.zoomCtx;
    const w: number = ctx.width;
    const h: number = ctx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    const tokens: ThemeTokens = this.resolveTokens();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = tokens.paperBackground;
    ctx.fillRect(0, 0, w, h);
    ctx.save();
    try {
      // ggg.d：doc px → screen px 直接放大倍率
      ctx.transform(this.magnification, 0, 0, this.magnification,
        -this.sourceX * this.magnification, -this.sourceY * this.magnification);
      this.renderContent(this.renderCtx, ctx, this.magnification);
    } finally {
      ctx.restore();
    }
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    // g0j：自动前进区（trailing 阴影带 + 区界线 + 中央 advance_tab 标记）。
    // ctx 为 vp 绘制空间（LengthMetricsUnit.DEFAULT）——直接用 vp 值，
    // 不得 vp2px（Phase 750 修复：747 版误乘 density 导致区带/标记放大）。
    const stripX: number = Math.max(0, w - this.advanceWidthVp);
    ctx.fillStyle = '#14000000';
    ctx.fillRect(stripX, 0, this.advanceWidthVp, h);
    ctx.fillStyle = tokens.border;
    ctx.fillRect(stripX, 0, 1, h);
    const tabW: number = 10;
    const tabH: number = 28;
    ctx.fillStyle = tokens.textSecondary;
    ctx.fillRect(stripX - tabW / 2, h / 2 - tabH / 2, tabW, tabH);
  }

  @Builder
  private ControlButton(label: Resource, glyph: string, onTap: () => void): void {
    Button(glyph)
      .width(48)
      .height(48)
      .fontSize(17)
      .fontColor(this.resolveTokens().textPrimary)
      .backgroundColor(Color.Transparent)
      // 原版 wfg.b：控制条按钮均为 48dp 点击区 + a11y 描述
      .accessibilityText(label)
      .enabled(this.panelEnabled)
      .opacity(this.panelEnabled ? 1 : 0.4)
      .onClick(() => {
        onTap();
      })
  }

  build() {
    Column() {
      // === wfg/ww2 控制条：拖拽柄 | 分隔 | Back | Forward | Return | Close ===
      Row() {
        // wfg.c：drag_handle + "Move Zoom View"，垂直拖动重新停靠
        // （qeg：Top/Bottom 两档；向下拖→Bottom，向上拖→Top）
        Text('≡')
          .fontSize(18)
          .fontColor(this.resolveTokens().textSecondary)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .accessibilityText($r('app.string.zoom_view_move'))
          .gesture(
            PanGesture({ direction: PanDirection.Vertical, distance: 8 })
              .onActionEnd((event: GestureEvent) => {
                this.onDockRequest(event.offsetY > 0);
              })
          )
        Divider()
          .vertical(true)
          .height(24)
          .color(this.resolveTokens().border)
          .margin({ left: 4, right: 4 })
        this.ControlButton($r('app.string.zoom_view_back'), '‹', () => {
          this.onStepBack();
        })
        this.ControlButton($r('app.string.zoom_view_forward'), '›', () => {
          this.onStepForward();
        })
        this.ControlButton($r('app.string.zoom_view_return'), '↩', () => {
          this.onReturnToInk();
        })
        this.ControlButton($r('app.string.zoom_view_close'), '✕', () => {
          this.onClose();
        })
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Start)
      .backgroundColor(this.resolveTokens().surface)
      // ggg.f panelInTopHalf → b7f "toolboxFlip"（scaleY ±1 动画）：
      // 面板停靠上半区时控制条镀铬垂直镜像；Harmony 顶部停靠≡上半区
      .scale({ x: 1, y: this.dockBottom ? 1 : -1 })

      // === g0j/fgg 放大画布区 ===
      Stack({ alignContent: Alignment.TopEnd }) {
        Canvas(this.zoomCtx)
          .width('100%')
          .height(this.surfaceHeightVp)
          .onReady(() => {
            this.draw();
          })
          .onTouch((event: TouchEvent) => {
            this.onZoomTouch(event);
          })
        // advance_tab 拖拽柄（横向调整自动前进区宽）
        Row()
          .width(14)
          .height(this.surfaceHeightVp)
          .margin({ right: this.advanceWidthVp - 7 })
          .gesture(
            PanGesture({ direction: PanDirection.Horizontal, distance: 4 })
              .onActionStart(() => {
                // offsetX 自手势起点累计——基准宽须在起点钉住，否则逐帧漂移
                this.advanceDragStartWidthVp = this.advanceWidthVp;
              })
              .onActionUpdate((event: GestureEvent) => {
                const next: number = this.advanceDragStartWidthVp - event.offsetX;
                // 原版 htd case 18：rh8.u(f, 48f, 336f) —— 夹取域 [48,336]
                this.advanceDragLastWidthVp = Math.max(ZOOM_ADVANCE_WIDTH_MIN_VP,
                  Math.min(ZOOM_ADVANCE_WIDTH_MAX_VP, next));
                this.onAdvanceRegionResize(this.advanceDragLastWidthVp);
              })
              .onActionEnd(() => {
                this.onAdvanceRegionCommit(this.advanceDragLastWidthVp);
              })
          )
          .accessibilityText($r('app.string.zoom_view_advance'))
      }
      .width('100%')
      .height(this.surfaceHeightVp)
      .clip(true)
    }
    .width('100%')
    .margin({ left: 8, right: 8 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(8)
    .clip(true)
    .shadow(ShadowStyle.OUTER_DEFAULT_MD)
    .onAreaChange(() => {
      this.draw();
    })
  }
}
