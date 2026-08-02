// T-022 选区覆盖层（虚线边框 + 8 项菜单）
import { Rect2D } from '../../core/model/GeometryTypes';
import { hilog } from '@kit.PerformanceAnalysisKit';

export enum SelectionMenuAction {
  COPY = 0,
  CUT = 1,
  DELETE = 2,
  SEND_FORWARD = 3,
  SEND_BACKWARD = 4,
  FLIP_H = 5,
  FLIP_V = 6,
  DESELECT = 7,
}

@Component
export struct SelectionOverlay {
  @Prop selectionRect: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @Prop visible: boolean = false;
  onMenuAction: (action: SelectionMenuAction) => void = () => {
  };

  build() {
    Stack() {
      if (this.visible) {
        // 虚线边框（Stack 内用 border 模拟）
        Stack()
          .width(this.selectionRect.right - this.selectionRect.left)
          .height(this.selectionRect.bottom - this.selectionRect.top)
          .position({ x: this.selectionRect.left, y: this.selectionRect.top })
          .border({ width: 1.5, color: '#3366FF', style: BorderStyle.Dashed })
        // 底部菜单按钮行（按钮 Block：阻止事件穿透到下层 Canvas，避免双路分发）
        Row() {
          Button('Copy').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu Copy clicked'); this.onMenuAction(SelectionMenuAction.COPY); })
          Button('Cut').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu Cut clicked'); this.onMenuAction(SelectionMenuAction.CUT); })
          Button('Del').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu Del clicked'); this.onMenuAction(SelectionMenuAction.DELETE); })
          Button('Fwd').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu Fwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_FORWARD); })
          Button('Bwd').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu Bwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_BACKWARD); })
          Button('FlipH').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu FlipH clicked'); this.onMenuAction(SelectionMenuAction.FLIP_H); })
          Button('FlipV').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu FlipV clicked'); this.onMenuAction(SelectionMenuAction.FLIP_V); })
          Button('OK').height(32).fontSize(12).hitTestBehavior(HitTestMode.Block).onClick(() => { hilog.info(0x0001, 'SelOverlay', 'menu OK clicked'); this.onMenuAction(SelectionMenuAction.DESELECT); })
        }
        .position({
          x: this.selectionRect.left,
          y: Math.max(this.selectionRect.bottom + 8, this.selectionRect.bottom),
        })
        .backgroundColor('#F0F4FF')
        .borderRadius(8)
        .padding(4)
      }
    }
    // 全屏 Transparent：自身不拦截触摸（Canvas 正常收事件），子组件按钮参与 hit
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
