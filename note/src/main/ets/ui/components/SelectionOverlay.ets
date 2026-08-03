// T-022 选区覆盖层（虚线边框 + 菜单；T-033 菜单替换为 ArkUI 原生 bindMenu）
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
        // 虚线边框（Stack 内用 border 模拟；展示类，无原生等价物，保留自绘）
        Stack()
          .width(this.selectionRect.right - this.selectionRect.left)
          .height(this.selectionRect.bottom - this.selectionRect.top)
          .position({ x: this.selectionRect.left, y: this.selectionRect.top })
          .border({ width: 1.5, color: '#3366FF', style: BorderStyle.Dashed })
        // 菜单：ArkUI 原生 bindMenu（T-033 替换自绘 Row+Button）；按钮 Block 阻止事件穿透
        Button('操作')
          .height(40)
          .fontSize(14)
          .hitTestBehavior(HitTestMode.Block)
          .position({
            x: this.selectionRect.left,
            y: Math.max(this.selectionRect.bottom + 8, this.selectionRect.bottom),
          })
          .bindMenu([
            { value: '复制', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Copy clicked'); this.onMenuAction(SelectionMenuAction.COPY); } },
            { value: '剪切', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Cut clicked'); this.onMenuAction(SelectionMenuAction.CUT); } },
            { value: '删除', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Del clicked'); this.onMenuAction(SelectionMenuAction.DELETE); } },
            { value: '置前', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Fwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_FORWARD); } },
            { value: '置后', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Bwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_BACKWARD); } },
            { value: '水平翻转', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipH clicked'); this.onMenuAction(SelectionMenuAction.FLIP_H); } },
            { value: '垂直翻转', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipV clicked'); this.onMenuAction(SelectionMenuAction.FLIP_V); } },
            { value: '完成', action: () => { hilog.info(0x0001, 'SelOverlay', 'menu OK clicked'); this.onMenuAction(SelectionMenuAction.DESELECT); } },
          ])
      }
    }
    // 全屏 Transparent：自身不拦截触摸（Canvas 正常收事件），子组件按钮参与 hit
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
