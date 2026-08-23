# Math 保存状态清除页面绑定证据

证据时间：2026-08-23（Asia/Shanghai）

## 竞态

`confirmOriginalMathLatex()` 和 `confirmMathInsert()` 都先 await `commitOriginalMath*()`。该 promise resolve 时页面
可能已经切换；随后无条件 `saveFailed = false` 会以旧页成功覆盖新页真实失败。

## Phase 309 契约

1. 清 `saveFailed` 前必须匹配发起 generation/pageId/currentPage；
2. 跨页成功保留持久化、undo history、editor 关闭和草稿清理；
3. 跨页失败继续记录 hilog 并释放 mathEditorBusy/historyBusy；
4. 同页 UI 更新、四态编辑器契约、type-23 单事务和 upload-immediately 语义不变。

## 边界

真实切页时序需要设备验收；本阶段只做静态契约、Desktop Replay 和双 HAP 打包。未启动模拟器、虚拟机、真机或
Hypium。
