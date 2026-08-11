import { Point2D } from '../../core/model/GeometryTypes';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

const CROP_HANDLE_HIT_SIZE: number = 32;
const CROP_HANDLE_SIZE: number = 12;
const CROP_TOOLBAR_WIDTH: number = 140;
const CROP_TOOLBAR_HEIGHT: number = 48;

export enum ImageCropHandle {
  TOP_LEFT = 0,
  TOP = 1,
  TOP_RIGHT = 2,
  RIGHT = 3,
  BOTTOM_RIGHT = 4,
  BOTTOM = 5,
  BOTTOM_LEFT = 6,
  LEFT = 7,
}

@Component
export struct ImageCropOverlay {
  @Prop visible: boolean = false;
  @Prop corners: Point2D[] = [];
  @Prop containerWidth: number = 0;
  @Prop containerHeight: number = 0;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private dragOffsetX: number = 0;
  private dragOffsetY: number = 0;
  onMove: (handle: ImageCropHandle, deltaX: number, deltaY: number) => void =
    (_handle: ImageCropHandle, _deltaX: number, _deltaY: number): void => {};
  onClose: () => void = (): void => {};
  onReset: () => void = (): void => {};
  onConfirm: () => void = (): void => {};

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private corner(index: number): Point2D {
    return this.corners.length === 4 ? this.corners[index] : { x: 0, y: 0 };
  }

  private handlePoint(handle: ImageCropHandle): Point2D {
    const topLeft: Point2D = this.corner(0);
    const topRight: Point2D = this.corner(1);
    const bottomRight: Point2D = this.corner(2);
    const bottomLeft: Point2D = this.corner(3);
    if (handle === ImageCropHandle.TOP_LEFT) {
      return topLeft;
    }
    if (handle === ImageCropHandle.TOP) {
      return this.midpoint(topLeft, topRight);
    }
    if (handle === ImageCropHandle.TOP_RIGHT) {
      return topRight;
    }
    if (handle === ImageCropHandle.RIGHT) {
      return this.midpoint(topRight, bottomRight);
    }
    if (handle === ImageCropHandle.BOTTOM_RIGHT) {
      return bottomRight;
    }
    if (handle === ImageCropHandle.BOTTOM) {
      return this.midpoint(bottomRight, bottomLeft);
    }
    if (handle === ImageCropHandle.BOTTOM_LEFT) {
      return bottomLeft;
    }
    return this.midpoint(bottomLeft, topLeft);
  }

  private midpoint(left: Point2D, right: Point2D): Point2D {
    return { x: (left.x + right.x) / 2, y: (left.y + right.y) / 2 };
  }

  private edgeLength(start: Point2D, end: Point2D): number {
    return Math.hypot(end.x - start.x, end.y - start.y);
  }

  private edgeAngle(start: Point2D, end: Point2D): string {
    return Math.atan2(end.y - start.y, end.x - start.x).toString() + 'rad';
  }

  private toolbarX(): number {
    let minimum: number = this.corner(0).x;
    let maximum: number = minimum;
    for (let index: number = 1; index < 4; index++) {
      minimum = Math.min(minimum, this.corner(index).x);
      maximum = Math.max(maximum, this.corner(index).x);
    }
    const centered: number = (minimum + maximum - CROP_TOOLBAR_WIDTH) / 2;
    return Math.max(8, Math.min(centered, this.containerWidth - CROP_TOOLBAR_WIDTH - 8));
  }

  private toolbarY(): number {
    let minimum: number = this.corner(0).y;
    let maximum: number = minimum;
    for (let index: number = 1; index < 4; index++) {
      minimum = Math.min(minimum, this.corner(index).y);
      maximum = Math.max(maximum, this.corner(index).y);
    }
    if (maximum + 12 + CROP_TOOLBAR_HEIGHT <= this.containerHeight - 8) {
      return maximum + 12;
    }
    return Math.max(8, minimum - CROP_TOOLBAR_HEIGHT - 12);
  }

  build() {
    Stack() {
      if (this.visible && this.corners.length === 4) {
        this.CropEdge(this.corner(0), this.corner(1))
        this.CropEdge(this.corner(1), this.corner(2))
        this.CropEdge(this.corner(2), this.corner(3))
        this.CropEdge(this.corner(3), this.corner(0))
        this.CropHandle(ImageCropHandle.TOP_LEFT)
        this.CropHandle(ImageCropHandle.TOP)
        this.CropHandle(ImageCropHandle.TOP_RIGHT)
        this.CropHandle(ImageCropHandle.RIGHT)
        this.CropHandle(ImageCropHandle.BOTTOM_RIGHT)
        this.CropHandle(ImageCropHandle.BOTTOM)
        this.CropHandle(ImageCropHandle.BOTTOM_LEFT)
        this.CropHandle(ImageCropHandle.LEFT)
        Row({ space: 4 }) {
          Button() {
            Image($r('app.media.crop_close'))
              .width(16)
              .height(16)
          }
            .width(40)
            .height(40)
            .fontSize(18)
            .backgroundColor(this.resolveTokens().control)
            .fontColor(this.resolveTokens().textPrimary)
            .accessibilityText($r('app.string.crop_close'))
            .onClick(() => this.onClose())
          Button() {
            Image($r('app.media.crop_reset'))
              .width(20)
              .height(20)
          }
            .width(40)
            .height(40)
            .fontSize(15)
            .backgroundColor(this.resolveTokens().control)
            .fontColor(this.resolveTokens().textPrimary)
            .accessibilityText($r('app.string.crop_reset'))
            .onClick(() => this.onReset())
          Button() {
            Image($r('app.media.crop_confirm'))
              .width(20)
              .height(14)
          }
            .width(44)
            .height(40)
            .fontSize(13)
            .backgroundColor(this.resolveTokens().accent)
            .fontColor(this.resolveTokens().onAccent)
            .accessibilityText($r('app.string.crop_confirm'))
            .onClick(() => this.onConfirm())
        }
        .width(CROP_TOOLBAR_WIDTH)
        .height(CROP_TOOLBAR_HEIGHT)
        .padding(4)
        .position({ x: this.toolbarX(), y: this.toolbarY() })
        .backgroundColor(this.resolveTokens().surface)
        .border({ width: 1, color: this.resolveTokens().border })
        .borderRadius(6)
        .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 2 })
        .hitTestBehavior(HitTestMode.Block)
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  CropEdge(start: Point2D, end: Point2D) {
    Stack()
      .width(this.edgeLength(start, end))
      .height(2)
      .position({ x: start.x, y: start.y - 1 })
      .backgroundColor(this.resolveTokens().accent)
      .rotate({ x: 0, y: 0, z: 1, angle: this.edgeAngle(start, end), centerX: 0, centerY: 1 })
  }

  @Builder
  CropHandle(handle: ImageCropHandle) {
    Stack() {
      Stack()
        .width(CROP_HANDLE_SIZE)
        .height(CROP_HANDLE_SIZE)
        .backgroundColor(this.resolveTokens().surface)
        .border({ width: 2, color: this.resolveTokens().accent })
    }
    .width(CROP_HANDLE_HIT_SIZE)
    .height(CROP_HANDLE_HIT_SIZE)
    .alignContent(Alignment.Center)
    .position({
      x: this.handlePoint(handle).x - CROP_HANDLE_HIT_SIZE / 2,
      y: this.handlePoint(handle).y - CROP_HANDLE_HIT_SIZE / 2,
    })
    .hitTestBehavior(HitTestMode.Block)
    .gesture(
      PanGesture({ fingers: 1 })
        .onActionStart(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        })
        .onActionUpdate((event: GestureEvent) => {
          const offsetX: number = event.offsetX === undefined ? this.dragOffsetX : event.offsetX;
          const offsetY: number = event.offsetY === undefined ? this.dragOffsetY : event.offsetY;
          this.onMove(handle, offsetX - this.dragOffsetX, offsetY - this.dragOffsetY);
          this.dragOffsetX = offsetX;
          this.dragOffsetY = offsetY;
        })
        .onActionEnd(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        })
        .onActionCancel(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        }),
    )
  }
}
