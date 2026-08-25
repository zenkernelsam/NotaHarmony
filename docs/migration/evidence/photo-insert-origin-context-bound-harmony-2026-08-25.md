# Harmony 证据：照片插入来源页上下文绑定

- 日期：2026-08-25
- 范围：`note/src/main/ets/ui/editor/NoteCanvasView.ets`
- 缺陷：照片选择器、剪贴板导入期间切页或移动视口后，旧实现会在异步完成后再读取页身份、纸张尺寸、缩放和中心点；UI 守卫无法阻止持久化目标漂移。
- 修复：新增不可变 `OriginalPhotoInsertOrigin`，在选择器前与剪贴板权限/导入前捕获 generation、pageId、纸张宽高、zoom 与 center。异步返回后要求来源页一致才继续；durable 插入完成后若来源过期则只记录并跳过历史与 UI 发布。
- Replay：
  - 新增 `d02-photo-insert-origin-context-bound.mjs`：12/12。
  - 加强 `d02-photo-ingress-disposal-bound.mjs`：9/9。
  - 相邻 `d02-photo-entry-state-bound.mjs`：通过。
  - 相邻 `d02-original-photo-picker-caller.mjs`：通过。
  - 相邻 `d02-original-photo-insert-immediate-decode.mjs`：通过。
- 静态验证：ArkTS 检查无错误；既有 unused/deprecated 警告保持不变。
