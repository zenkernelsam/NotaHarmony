// T-022 选区覆盖层（虚线边框 + 菜单；T-033 菜单替换为 ArkUI 原生 bindMenu）
import { Rect2D } from '../../core/model/GeometryTypes';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import {
  SELECTION_MENU_BUTTON_HEIGHT, SELECTION_MENU_BUTTON_WIDTH, selectionOverlayPosition,
  standalonePastePosition,
} from './SelectionOverlayLayout';

export enum SelectionMenuAction {
  COPY = 0,
  CUT = 1,
  DELETE = 2,
  SEND_FORWARD = 3,
  SEND_BACKWARD = 4,
  FLIP_H = 5,
  FLIP_V = 6,
  DESELECT = 7,
  PASTE = 8,
  CROP = 9,
  LOCK = 10,
}

@Component
export struct SelectionOverlay {
  @Prop selectionRect: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @Prop visible: boolean = false;
  @Prop canPaste: boolean = false;
  @Prop canFlip: boolean = false;
  @Prop canCrop: boolean = false;
  @Prop canLock: boolean = false;
  @Prop positionLocked: boolean = false;
  @Prop containerWidth: number = 0;
  @Prop containerHeight: number = 0;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onMenuAction: (action: SelectionMenuAction) => void = () => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Stack() {
      if (this.visible) {
        // 虚线边框（Stack 内用 border 模拟；展示类，无原生等价物，保留自绘）
        Stack()
          .width(this.selectionRect.right - this.selectionRect.left)
          .height(this.selectionRect.bottom - this.selectionRect.top)
          .position({ x: this.selectionRect.left, y: this.selectionRect.top })
          .border({ width: 1.5, color: this.resolveTokens().accent, style: BorderStyle.Dashed })
        // 菜单：ArkUI 原生 bindMenu（T-033 替换自绘 Row+Button）；按钮 Block 阻止事件穿透
        Button($r('app.string.selection_actions'))
          .width(SELECTION_MENU_BUTTON_WIDTH)
          .height(SELECTION_MENU_BUTTON_HEIGHT)
          .fontSize(14)
          .hitTestBehavior(HitTestMode.Block)
          .position({
            x: selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, this.canPaste).x,
            y: selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, this.canPaste).actionY,
          })
          .bindMenu(this.buildSelectionMenu())
      }
      if (this.canPaste) {
        Button($r('app.string.paste'))
          .width(SELECTION_MENU_BUTTON_WIDTH)
          .height(SELECTION_MENU_BUTTON_HEIGHT)
          .fontSize(14)
          .hitTestBehavior(HitTestMode.Block)
          .position({
            x: this.visible ? selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, true).x : standalonePastePosition(this.containerWidth),
            y: this.visible ? selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, true).pasteY : 16,
          })
          .onClick(() => {
            hilog.info(0x0001, 'SelOverlay', 'Paste clicked');
            this.onMenuAction(SelectionMenuAction.PASTE);
          })
      }
    }
    // 全屏 Transparent：自身不拦截触摸（Canvas 正常收事件），子组件按钮参与 hit
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  private buildSelectionMenu(): MenuElement[] {
    const items: MenuElement[] = [
      { value: $r('app.string.copy'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Copy clicked'); this.onMenuAction(SelectionMenuAction.COPY); } },
      { value: $r('app.string.cut'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Cut clicked'); this.onMenuAction(SelectionMenuAction.CUT); } },
      { value: $r('app.string.delete'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Del clicked'); this.onMenuAction(SelectionMenuAction.DELETE); } },
      { value: $r('app.string.bring_forward'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Fwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_FORWARD); } },
      { value: $r('app.string.send_backward'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Bwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_BACKWARD); } },
    ];
    if (this.canFlip) {
      items.push({ value: $r('app.string.flip_horizontal'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipH clicked'); this.onMenuAction(SelectionMenuAction.FLIP_H); } });
      items.push({ value: $r('app.string.flip_vertical'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipV clicked'); this.onMenuAction(SelectionMenuAction.FLIP_V); } });
    }
    if (this.canCrop) {
      items.push({ value: $r('app.string.crop'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Crop clicked'); this.onMenuAction(SelectionMenuAction.CROP); } });
    }
    if (this.canLock) {
      items.push({ value: this.positionLocked ? $r('app.string.unlock') : $r('app.string.lock'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Lock clicked'); this.onMenuAction(SelectionMenuAction.LOCK); } });
    }
    items.push({ value: $r('app.string.done'), action: () => { hilog.info(0x0001, 'SelOverlay', 'menu OK clicked'); this.onMenuAction(SelectionMenuAction.DESELECT); } });
    return items;
  }
}
