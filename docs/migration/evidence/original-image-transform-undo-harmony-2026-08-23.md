# Harmony 图片 Transform Undo 资产刷新证据（2026-08-23）

## 现场证据

1. `NoteCanvasView.confirmImageCrop()` 已生成 `beforeImages=[before]`、`afterImages=[after]`，并推入
   `TRANSFORM_ELEMENTS`；持久化继续走既有 crop type-23 边界。
2. `UndoRedoManager` 对 `TRANSFORM_ELEMENTS` 估算 `estimateImages(beforeImages)` 与
   `estimateImages(afterImages)`，证明该 action 属于 image metadata-changing history。
3. `actionTouchesImages()` 只识别 `ERASE_ELEMENTS`、`DELETE_ELEMENTS` 和 `ADD_ELEMENTS`，遗漏了上述
   transform images，导致 Undo/Redo 后共享 bitmap 不刷新。

## 原版参考

Desktop 只读证据继续使用 Android `g3.java` 共享显示解码与 `hp5.java` IMAGE block registers：bitmap 结果由
decode 参数和 block metadata 决定；metadata 变化后不能复用旧像素快照。本阶段未在 Desktop 写入。

## 修复

`actionTouchesImages()` 增加 `TRANSFORM_ELEMENTS` 分支：只要 before/after 任一 image snapshot 存在即刷新
image assets。运行态验证仍禁止；以静态 Replay 和 clean 双 HAP 作为本阶段边界。
