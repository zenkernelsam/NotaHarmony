# 粘贴失败反馈页面绑定证据

证据时间：2026-08-23（Asia/Shanghai）

## 竞态

`startOriginalClipboardImagePaste()` 的 catch 位于多次 await 之后。若 `importOriginalClipboardImage()` 或
`insertOriginalPhotos()` 失败时用户已切页，旧流程会直接执行：

1. `promptAction.showToast(original_photo_insert_failed)`；
2. `insertOriginalPhotos()` 内部 `reportSaveFailure()`；
3. 新页面被置为 `saveFailed = true`。

这会让新页承担旧页失败的 UI 状态，并抑制后续同页真实失败的首个提示。

## Phase 305 契约

1. 通用图片插入只在发起 generation/pageId/currentPage 匹配时调用 `reportSaveFailure()`；
2. 剪贴板专用失败 toast 只在发起 generation/pageId 匹配时显示；
3. 跨页失败继续记录 hilog，不静默吞掉诊断；
4. `photoImportBusy` 与 `historyBusy` 仍在 finally 中释放，不阻塞新页操作；
5. 成功前缀、部分失败计数、undo history 和数据库事务边界保持 Phase 290 契约。

## 边界

真实切页与失败注入矩阵需要设备验收；本阶段只做静态契约、Desktop Replay 和双 HAP 打包。未启动模拟器、虚拟机、
真机或 Hypium。
