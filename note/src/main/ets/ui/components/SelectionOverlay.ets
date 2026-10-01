// T-022 选区覆盖层（虚线边框 + 菜单；T-033 菜单替换为 ArkUI 原生 bindMenu）
import { Rect2D, Point2D } from '../../core/model/GeometryTypes';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import {
  SELECTION_HANDLE_SIZE, SELECTION_MENU_BUTTON_HEIGHT, SELECTION_MENU_BUTTON_WIDTH,
  SELECTION_ROTATE_HANDLE_OFFSET, selectionOverlayPosition,
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
  GROUP = 11,
  UNGROUP = 12,
  EDIT_MATH = 13,
  DUPLICATE = 14,
  SEND_TO_FRONT = 15,
  SEND_TO_BACK = 16,
  // 原版 deselectMode 的确认/取消（k2f onConfirm/onCancelDeselectMode）。
  DESELECT_CONFIRM = 17,
  DESELECT_CANCEL = 18,
  // 原版 dsc.STYLE（ordinal 0，菜单首项）：打开选区样式表面。
  STYLE = 19,
}

@Component
export struct SelectionOverlay {
  @Prop selectionRect: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @Prop visible: boolean = false;
  @Prop canPaste: boolean = false;
  @Prop canFlip: boolean = false;
  @Prop canCrop: boolean = false;
  @Prop canLock: boolean = false;
  @Prop canGroup: boolean = false;
  @Prop canUngroup: boolean = false;
  @Prop canEditMath: boolean = false;
  @Prop canStyle: boolean = false;
  @Prop canDeselect: boolean = false;
  @Prop canReorder: boolean = true;
  @Prop positionLocked: boolean = false;
  @Prop lockedOnly: boolean = false;
  @Prop menuEnabled: boolean = true;
  @Prop deselectMode: boolean = false;
  @Prop photoImportLeaseActive: boolean = false;
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
        // 原版选区覆盖层角柄（htc.e/qpi.b 自由变换入口）：四角圆点 +
        // 顶边上方旋转柄（msc.c selectionHasRotationHandle）。
        // 命中由 NoteCanvasView.onTouchDown 判定（装饰性，不拦截）。
        if (!this.deselectMode && !this.photoImportLeaseActive) {
          ForEach([
            { x: this.selectionRect.left, y: this.selectionRect.top },
            { x: this.selectionRect.right, y: this.selectionRect.top },
            { x: this.selectionRect.right, y: this.selectionRect.bottom },
            { x: this.selectionRect.left, y: this.selectionRect.bottom },
          ], (corner: Point2D) => {
            Circle()
              .width(SELECTION_HANDLE_SIZE)
              .height(SELECTION_HANDLE_SIZE)
              .fill(this.resolveTokens().control)
              .stroke(this.resolveTokens().accent)
              .strokeWidth(1.5)
              .position({ x: corner.x - SELECTION_HANDLE_SIZE / 2,
                y: corner.y - SELECTION_HANDLE_SIZE / 2 })
          }, (corner: Point2D): string => `${corner.x},${corner.y}`)
          Circle()
            .width(SELECTION_HANDLE_SIZE)
            .height(SELECTION_HANDLE_SIZE)
            .fill(this.resolveTokens().control)
            .stroke(this.resolveTokens().accent)
            .strokeWidth(1.5)
            .position({
              x: (this.selectionRect.left + this.selectionRect.right) / 2 -
                SELECTION_HANDLE_SIZE / 2,
              y: this.selectionRect.top - SELECTION_ROTATE_HANDLE_OFFSET -
                SELECTION_HANDLE_SIZE / 2,
            })
        }
        // 菜单：ArkUI 原生 bindMenu（T-033 替换自绘 Row+Button）；按钮 Block 阻止事件穿透
        Button($r('app.string.selection_actions'))
          .width(SELECTION_MENU_BUTTON_WIDTH)
          .height(SELECTION_MENU_BUTTON_HEIGHT)
          .fontSize(14)
          .enabled(this.menuEnabled)
          .hitTestBehavior(HitTestMode.Block)
          .position({
            x: selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, false).x,
            y: selectionOverlayPosition(this.selectionRect, this.containerWidth,
              this.containerHeight, false).actionY,
          })
          .bindMenu(this.buildSelectionMenu())
      }
    }
    // 全屏 Transparent：自身不拦截触摸（Canvas 正常收事件），子组件按钮参与 hit
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  private buildSelectionMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    // 原版 deselectMode（k2f 确认/取消条）：模式下菜单只留确认/取消。
    if (this.deselectMode) {
      items.push(
        { value: $r('app.string.done'), action: () => { this.onMenuAction(SelectionMenuAction.DESELECT_CONFIRM); } },
        { value: $r('app.string.cancel'), action: () => { this.onMenuAction(SelectionMenuAction.DESELECT_CANCEL); } });
      return items;
    }
    if (!this.photoImportLeaseActive) {
      // 原版 urf z 支：旗开 + lsf 单元素且实体已锁（cjm.h）→ xqf([UNLOCK],∅)。
      // 点选锁定元素时菜单仅 "Unlock" 一行（锁定元素不可样式/删移——只能解锁）。
      // LOCK 合并行在 positionLocked=true 时渲染 Unlock 标签/图标（ADR-0586）。
      if (this.lockedOnly) {
        items.push({ value: $r('app.string.unlock'), icon: $r('app.media.selmenu_unlock'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Lock clicked'); this.onMenuAction(SelectionMenuAction.LOCK); } });
        return items;
      }
      // 原版 urf 装配序：实体专属动作先行——CROP（lsf/l97 图像）→
      // EDIT_MATH（lsf/cv9 数学）→ STYLE（含可样式化 ink；vvh 文本纸
      // 实体另受 h35.S0=TEXT_BOX_PAPER qd5 调试门，生产恒假）。
      // r68 菜单项为 icon+label 行——MenuElement.icon 挂原版 selection_menu_* 矢量。
      if (this.canCrop) {
        items.push({ value: $r('app.string.crop'), icon: $r('app.media.selmenu_crop'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Crop clicked'); this.onMenuAction(SelectionMenuAction.CROP); } });
      }
      if (this.canEditMath) {
        items.push({ value: $r('app.string.edit_math'), icon: $r('app.media.selmenu_edit_math'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Edit Math clicked'); this.onMenuAction(SelectionMenuAction.EDIT_MATH); } });
      }
      if (this.canStyle) {
        items.push({ value: $r('app.string.selection_style'),
          icon: $r('app.media.selmenu_style'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Style clicked'); this.onMenuAction(SelectionMenuAction.STYLE); } });
      }
      items.push(
        { value: $r('app.string.copy'), icon: $r('app.media.selmenu_copy'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Copy clicked'); this.onMenuAction(SelectionMenuAction.COPY); } });
    }
    if (this.photoImportLeaseActive) {
      return items;
    }
    // 原版 urf 主行序：CROP?/EDIT_MATH?/STYLE?/COPY/CUT/DUPLICATE/
    // GROUP|UNGROUP?/LOCK|UNLOCK?/DESELECT?/DELETE/MORE?；MORE 子菜单
    // （arrayList2）序=FLIP_H/FLIP_V/CONVERT_TO_MATH/CONVERT_TO_TEXT/
    // SAVE_AS_STICKER/SEND_TO_FRONT/SEND_TO_BACK/SEND_FORWARD/SEND_BACKWARD。
    // (*原版 dhb case15 即 throw NotImplementedError——FIT_TO_PAGE 上游即死项)
    // ADR-0645 全表登记：CONVERT_* 走 MyScript iink（xsc.p() 后端门禁，
    // Harmony 无生产 OCR provider → fail-closed 缺省）；SAVE_AS_STICKER
    // 挂 h35.z0=STICKERS rd5 InternalUserOnly（P1436 ADR-1371）；LOCK 行
    // 挂 h35.I=POSITION_LOCKED td5 灰度旗（远端键 androidPositionLocked
    // 不在 defaults 表——生产缺省 false；本地实现保留=已移植+旗门登记，
    // 与 textOnly 同判例）；MORE 双子菜单按 msc.b 语义平铺至行尾
    // （本实现单行全量列出）；LOCK 合并 UNLOCK（ADR-0586）。
    // PASTE rides the menu as a registered adaptation (original renders a
    // floating paste chip t6b); it sits with the clipboard cluster.
    items.push(
      { value: $r('app.string.cut'), icon: $r('app.media.selmenu_cut'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Cut clicked'); this.onMenuAction(SelectionMenuAction.CUT); } },
      { value: $r('app.string.duplicate_note'), icon: $r('app.media.selmenu_duplicate'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Duplicate clicked'); this.onMenuAction(SelectionMenuAction.DUPLICATE); } });
    if (this.canPaste) {
      items.push({ value: $r('app.string.paste'), icon: $r('app.media.selmenu_paste'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Paste clicked'); this.onMenuAction(SelectionMenuAction.PASTE); } });
    }
    if (this.canGroup) {
      items.push({ value: $r('app.string.group'), icon: $r('app.media.selmenu_group'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Group clicked'); this.onMenuAction(SelectionMenuAction.GROUP); } });
    }
    if (this.canUngroup) {
      // 原版 group/ungroup 共用 ui_designsystem__group 图标。
      items.push({ value: $r('app.string.ungroup'), icon: $r('app.media.selmenu_group'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Ungroup clicked'); this.onMenuAction(SelectionMenuAction.UNGROUP); } });
    }
    if (this.canLock) {
      items.push({ value: this.positionLocked ? $r('app.string.unlock') : $r('app.string.lock'),
        icon: this.positionLocked ? $r('app.media.selmenu_unlock') : $r('app.media.selmenu_lock'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Lock clicked'); this.onMenuAction(SelectionMenuAction.LOCK); } });
    }
    // 原版 urf：DESELECT 仅 isf 装配——绘制完成（hsf→isf）与集合
    // 程序化选区可选；lsf 单元素点选、jsf 组点选不出现此行。
    if (this.canDeselect) {
      items.push({ value: $r('app.string.deselect'), icon: $r('app.media.selmenu_deselect'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Deselect clicked'); this.onMenuAction(SelectionMenuAction.DESELECT); } });
    }
    items.push(
      { value: $r('app.string.delete'), icon: $r('app.media.selmenu_delete'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Del clicked'); this.onMenuAction(SelectionMenuAction.DELETE); } });
    // --- MORE 子菜单平铺（msc.b 双行 → 单行尾段）---
    if (this.canFlip) {
      items.push({ value: $r('app.string.flip_horizontal'), icon: $r('app.media.selmenu_flip_h'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipH clicked'); this.onMenuAction(SelectionMenuAction.FLIP_H); } });
      items.push({ value: $r('app.string.flip_vertical'), icon: $r('app.media.selmenu_flip_v'),
        action: () => { hilog.info(0x0001, 'SelOverlay', 'menu FlipV clicked'); this.onMenuAction(SelectionMenuAction.FLIP_V); } });
    }
    // 原版 urf：SEND_* 四行仅 msfVar.f()（z-orderable 集）非空时装配，
    // 序=TO_FRONT/TO_BACK/FORWARD/BACKWARD；纯组绘制选区（isf.q 空）
    // 不产四行。send_forward/send_to_front 共用 selection_menu_send_forward；
    // send_backward/send_to_back 共用 selection_menu_send_backward。
    if (this.canReorder) {
      items.push(
        { value: $r('app.string.send_to_front'), icon: $r('app.media.selmenu_forward'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu ToFront clicked'); this.onMenuAction(SelectionMenuAction.SEND_TO_FRONT); } },
        { value: $r('app.string.send_to_back'), icon: $r('app.media.selmenu_backward'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu ToBack clicked'); this.onMenuAction(SelectionMenuAction.SEND_TO_BACK); } },
        { value: $r('app.string.bring_forward'), icon: $r('app.media.selmenu_forward'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Fwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_FORWARD); } },
        { value: $r('app.string.send_backward'), icon: $r('app.media.selmenu_backward'),
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Bwd clicked'); this.onMenuAction(SelectionMenuAction.SEND_BACKWARD); } });
    }
    return items;
  }
}
