// T-022 选区覆盖层（虚线边框 + 菜单；T-033 菜单替换为 ArkUI 原生 bindMenu）
import { Rect2D, Point2D } from '../../core/model/GeometryTypes';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import {
  SELECTION_HANDLE_DOT_INNER, SELECTION_HANDLE_DOT_OUTER, SELECTION_HANDLE_SIZE,
  SELECTION_MENU_BUTTON_HEIGHT, SELECTION_MENU_BUTTON_WIDTH,
  SELECTION_ROTATE_DOT_INNER, SELECTION_ROTATE_DOT_OUTER, SELECTION_ROTATE_HANDLE_STEM,
  selectionOverlayPosition,
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
  // 原版 gsf.g：isf.k（绘制轨迹）非空 → 实线界；程序化集合 → 虚线界。
  @Prop selectionDrawn: boolean = false;
  // 原版 gsf.h：lsf 单元素点选不产画布外层界框（成员级铬件承担）。
  @Prop selectionBorderless: boolean = false;
  // 原版 gsf.h：jsf 组点选外层界为 e=#FFB3B3B3 灰实线 2dp。
  @Prop selectionOuterGray: boolean = false;
  // 原版 xnm.c/gsf.c：lsf 仅未锁图片/文本成员框带柄；笔画/形状/数学成员
  // 与已锁成员不产手柄。
  @Prop selectionHandlesHidden: boolean = false;
  // 原版 yj8 布局方向：RTL 时旋转柄茎锚左边中点并反向延出
  //（gsf.i:164-167 sbe.a vs sbe.c；gsf.e f3=±56/f2）。
  @Prop selectionRotateHandleRtl: boolean = false;
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
        // 原版 gsf.g/sen.t 界式样：绘制型选区（isf.k 轨迹非空）→ 实线
        // 2dp 界；程序化集合（k=null：粘贴/全选）→ 4dp 虚线界；固定色
        // #FF4278FF（qxk.e(4282546431)，不随主题）；jsf 组点选 → gsf.c
        // e=#FFB3B3B3 灰实线 2dp；lsf 单元素点选 → gsf.h 早退无外框；
        // deselectMode（isf.h）→ gsf.c = a@0.32 降色。
        if (!this.selectionBorderless) {
          Stack()
            .width(this.selectionRect.right - this.selectionRect.left)
            .height(this.selectionRect.bottom - this.selectionRect.top)
            .position({ x: this.selectionRect.left, y: this.selectionRect.top })
            .border({
              width: this.selectionDrawn || this.selectionOuterGray ? 2 : 4,
              color: this.selectionOuterGray ? '#FFB3B3B3' : '#FF4278FF',
              style: this.selectionDrawn || this.selectionOuterGray ?
                BorderStyle.Solid : BorderStyle.Dashed,
            })
            .opacity(this.deselectMode ? 0.32 : 1.0)
        }
        // 原版 gsf.b/e 手柄（htc.e/qpi.b 自由变换入口）：角柄=半径 12dp
        // 白（p52.e）+半径 10dp 蓝（gsf.a）双层圆；旋转柄=右（RTL 左）边
        // 中点锚 + 水平茎 56vp 延出 + 半径 16dp 白/14dp #444DE0 端点双层圆。
        // 命中由 NoteCanvasView.onTouchDown 判定（装饰性，不拦截）。
        if (!this.deselectMode && !this.photoImportLeaseActive &&
          !this.selectionHandlesHidden) {
          ForEach([
            { x: this.selectionRect.left, y: this.selectionRect.top },
            { x: this.selectionRect.right, y: this.selectionRect.top },
            { x: this.selectionRect.right, y: this.selectionRect.bottom },
            { x: this.selectionRect.left, y: this.selectionRect.bottom },
          ], (corner: Point2D) => {
            Stack() {
              Circle()
                .width(SELECTION_HANDLE_DOT_OUTER)
                .height(SELECTION_HANDLE_DOT_OUTER)
                .fill('#FFFFFFFF')
              Circle()
                .width(SELECTION_HANDLE_DOT_INNER)
                .height(SELECTION_HANDLE_DOT_INNER)
                .fill('#FF4278FF')
            }
            .position({ x: corner.x - SELECTION_HANDLE_DOT_OUTER / 2,
              y: corner.y - SELECTION_HANDLE_DOT_OUTER / 2 })
          }, (corner: Point2D): string => `${corner.x},${corner.y}`)
          // gsf.e：茎=右（RTL 左）边中点 ±56vp（gsf.e:87
          // f3=56/f2·(dir==F?1:−1)、gsf.i 锚 sbe.c/sbe.a 边中点）；
          // 茎宽 2vp、色 d=#FF444DE0。
          Rect()
            .width(SELECTION_ROTATE_HANDLE_STEM)
            .height(2)
            .fill('#FF444DE0')
            .position({
              x: this.selectionRotateHandleRtl
                ? this.selectionRect.left - SELECTION_ROTATE_HANDLE_STEM
                : this.selectionRect.right,
              y: (this.selectionRect.top + this.selectionRect.bottom) / 2 - 1,
            })
          Stack() {
            Circle()
              .width(SELECTION_ROTATE_DOT_OUTER)
              .height(SELECTION_ROTATE_DOT_OUTER)
              .fill('#FFFFFFFF')
            Circle()
              .width(SELECTION_ROTATE_DOT_INNER)
              .height(SELECTION_ROTATE_DOT_INNER)
              .fill('#FF444DE0')
          }
          .position({
            x: (this.selectionRotateHandleRtl
              ? this.selectionRect.left - SELECTION_ROTATE_HANDLE_STEM
              : this.selectionRect.right + SELECTION_ROTATE_HANDLE_STEM) -
              SELECTION_ROTATE_DOT_OUTER / 2,
            y: (this.selectionRect.top + this.selectionRect.bottom) / 2 + 1 -
              SELECTION_ROTATE_DOT_OUTER / 2,
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
          action: () => { hilog.info(0x0001, 'SelOverlay', 'menu Unlock clicked'); this.onMenuAction(SelectionMenuAction.LOCK); } });
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
    // P1442 终局裁决（1.4.2 urf/wqf 精证）：
    //   CONVERT_TO_MATH(Q)=h45.b(h35.e0)=td5 androidMathHandwritingRecognition
    //     defaults=false → 生产旗关 + iink 私有识别引擎，双重 fail-closed；
    //   CONVERT_TO_TEXT(R)=全选成员 mn7 笔画且任一 oim.b(k!=HIGHLIGHTER) 即出行，
    //     但分发链入 MyScript iink → fail-closed（行缺省即正确）；
    //   SAVE_AS_STICKER(T)=h45.b(h35.z0)=STICKERS rd5 InternalUserOnly →
    //     生产恒不可达；
    //   FIT_TO_PAGE：wqfVar17 枚举体从未赋静态字段（urf 无 add 点、
    //     m36 case16 死渲染支；1.0.3 dhb case15 亦 NotImplementedError）
    //     → 原版即死项。
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
