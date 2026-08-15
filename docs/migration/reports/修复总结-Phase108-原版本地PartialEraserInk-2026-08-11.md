# Phase 108 历史总结：本地 Partial Eraser Ink（结论已由 Phase 237 更正）

## 2026-08-15 更正

Phase 108 将原版 `u16.PARTIAL_ERASER((byte) 5)` 和 `kt1/u5j.g(...)` 证据解释为“本地手势最终持久化一条
tool-5 CREATE_INK”。该结论不完整，并导致 Harmony 曾把 `destination-out` Ink 当成永久页面实体。

Phase 237 重新闭环 `dh5 → jt1 → n8j/o8j → wc mode 3` 后确认：

- tool 5 是 partial-erase 交互输入和兼容数据语义，不等于最终页面表示；
- 普通 Ink 被裁成零至多个新 Ink 残片；
- 原 source Ink 被 DELETE_ENTITIES；
- AudioLinked Ink 的每个残片按路径区间重算 `audioStartTime/audioDuration`；
- 原版还会替换 Group member、删除空 Group，并结束 transient interaction。

因此，Phase 108 关于“永久 tool-5 Ink + ADD_STROKE Undo/Redo + 整页 destination-out 图层”的本地 writer
结论已废止。当前契约见 ADR-0214 与 Phase 237 总结。

## Phase 108 当时实际完成且仍保留的部分

- 模型、CREATE_INK decoder/encoder 与 renderer 能识别 tool 5，保证已有或外来原版数据不会被静默降成普通 Pen。
- tool-5 Ink 不参与普通 SelectionTool 与 eraser hit testing，避免兼容实体被当作普通可编辑 Ink。
- partial eraser 不再把命中的 Shape/Text/Image/Math 整体删除；对象删除只属于 whole eraser。
- touch cancellation、page generation 与 original identity reservation 的防跨页/防复用加固，为后续 canonical
  authoring 继续复用。

## Phase 108 的历史验证记录

- 当时 ArkTS fixture 只覆盖 CREATE_INK tool 5 编解码与 reducer eligibility。
- 当时专项 replay 输出为
  `localPartialEraser=original-create-tool5-zorder-undo-redo-paper-safe`，全量 replay 为 `TOTAL=94 FAILED=0`。
- 当时 clean 后 `note@ohosTest` 与 `note@default` 均构建通过；这些结果只能证明旧实现内部自洽，不能证明
  持久语义与原版一致。

## 当前替代实现

Phase 237 已将本地普通 Ink partial erase 改为 CREATE_INK remnants + DELETE_ENTITIES sources，并增加专用持久
Undo/Redo、单 revision 事务、search 重建、残片顺序历史与失败回滚验证。仍未完成的 Group、Shape、Pencil/custom
outline 和 transient protocol 边界以 Phase 237 文档为准。
