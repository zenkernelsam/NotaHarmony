# Phase 108 修复总结：原版本地 Partial Eraser Ink

## 原版证据

- 原版 `u16` 明确声明 `PARTIAL_ERASER((byte) 5)`。
- 原版 `kt1` 的局部橡皮分支选择 `u16.PARTIAL_ERASER`，随后仍调用 `u5j.g(...)` 创建 Ink；因此它是
  持久化的 tool-5 CREATE_INK，不是把每条命中 Ink 改写为 MODIFY_INK center-path replacement。
- MODIFY_INK field 8 仍是独立的中心路径寄存器语义，保留给后续本地 writer 阶段，不能与局部橡皮混为一谈。

## 已完成修复

- `RenderSpec` 新增可选 `isPartialEraser`；CREATE_INK encoder 写出 tool 5，原版 reducer 接受并物化该
  工具，MODIFY_INK 重建和自有包校验均保留标志。
- 原版对齐页面上的局部橡皮在 touch-down 消费预留 operation identity，创建 fixed-width tool-5 Ink，
  追加统一元素层序并走 ADD_STROKE Undo action；`persist(true)` 将其写入原版 CREATE_INK outbound，
  后续 Undo/Redo 复用 DELETE_ENTITIES 删除/恢复同一 canonical Ink。
- Cancel、第二指接管或指针丢失会丢弃已消费 identity，并只为当前 page-load generation 重新预留；成功
  persistence 后再 rearm，避免复用 operation identity 或跨页串写。
- renderer 使用 Ink 自身宽度、round cap/join 和 `destination-out` 合成；单点 tap 通过同点 lineTo 形成
  可见圆帽。tool-5 Ink 不参与 SelectionTool，也不会被 EraserEngine 当普通 Ink 再次命中。
- 为保护纸张/PDF 背景，仅当页面存在 tool-5 Ink 时，把统一层序元素绘制到透明离屏内容层，再叠到纸张；
  bitmap 始终在 `finally` 中关闭。这样 eraser 只擦较早内容，后画 Ink 仍可覆盖其上，Undo 也可恢复。
- 边修边审纠正旧逻辑：partial eraser 不再把命中的 Shape/Text/Image/Math 整体删除；只有 whole eraser
  执行对象删除。不能进入原版 authoring 的旧/混合页面继续使用已有 mask fallback。

## 验证

- ArkTS fixture 覆盖 CREATE_INK tool 5 编解码与 reducer eligibility。
- 专项 replay 输出：
  `localPartialEraser=original-create-tool5-zorder-undo-redo-paper-safe`。
- 更新旧 Shape consumer replay，使其约束参数化 render context；全量桌面 replay 为
  `TOTAL=94 FAILED=0`。
- 增量 `note@ohosTest` 为 `BUILD SUCCESSFUL`。最终执行 `hvigor clean` 后，严格串行构建
  `note@ohosTest` 与 `note@default`，两套均为 `BUILD SUCCESSFUL`；对应 unsigned HAP 均已落盘。

## 仍待后续

- 本阶段没有虚报本地 MODIFY_INK center-path replacement、ADD_PATH_ELEMENTS streaming、其余元素
  outbound authoring 或设备像素/性能已经完成。
- 未启动模拟器、虚拟机、真机或 Hypium。Goal 保持 active。
