# Phase 241 修复总结：原版 Partial Eraser 临时预览与提交结束

## 本阶段目标

在 Phase 237–240 已闭环 durable Ink/Shape remnants、Group replacement、source deletion 与持久
Undo/Redo 的基础上，继续严格对齐 Notability Android 1.0.3 的 partial-eraser 手势生命周期：按下时建立
transient tool-5 Ink，移动时实时追加，抬手后在 durable replacement 等待期间保持预览，并在成功、明确失败或
取消时结束；不得再把 tool-5 路径当作永久页面实体。

## 原版结论

- `kt1.d()` 在 `d04.J` 工具按下时选择 `u16.PARTIAL_ERASER`，创建 tool-5 Ink。
- `bt1` 用 transient `wq9(..., true, ...)` 派发 CREATE_INK，并保存 active interaction ID。
- `kt1.c()` 的 move 只向该 transient ID 追加 ADD_PATH_ELEMENTS。
- `dh5 → jt1 → wc` 先完成 durable remnants、Group 与 source deletion，最后才发送
  `TRANSIENT_INTERACTION_ENDED`。
- `a5g → fg2` 的 cancel 只结束 transient interaction，不把 preview 持久化。
- 详细证据与原文件 SHA-256 见
  `docs/migration/evidence/original-partial-eraser-transient-preview-jadx-2026-08-16.md`。

## 已完成修复

1. 新增 `OriginalPartialEraserTransientPreview`，状态严格限定为
   `IDLE → TRACKING → AWAITING_COMMIT → IDLE`；preview 只保存在内存中，不进入
   `completedStrokes`、`elementOrder`、snapshot、operation log 或 durable outbox。
2. pointer-down 使用当前 eraser width 建立 tool-5 `StrokeElementData`，move 去重并追加同一画布路径，实时更新
   bounds 与渲染；pointer-up 把同一路径交给 Phase 239/240 的 Ink/Shape boolean eraser。
3. preview 在 durable transaction 等待期间继续保留，避免“抬手后先闪回原内容、提交后再消失”；无命中、
   local fallback、transaction rejection、transaction success、Cancel、双指接管、换页、重新加载和生命周期离开
   都有明确清理路径。
4. 每次 preview 使用单调 token。旧 transaction 的完成回调无法清除后来建立的新手势，避免异步跨手势串扰。
5. preview 最多接受 65,535 个点；非法点或超预算时整次手势 fail-closed，不允许用被截断的路径执行实际删除。
6. 常见 Stroke→Text 页面新增 `StrokeLayerManager.compositeWithPartialEraser()`：只复制累积 dirty crop 内的
   completed handwriting bitmap，在隔离层执行 destination-out，再重画 Text 前景；纸张背景不会被挖穿，Text
   也不会被普通 handwriting mask 暂时隐藏。
7. 含 Shape/Image/Math 或 mixed z-order 的页面继续使用统一内容离屏层，避免破坏既有元素顺序；后续真机回归需
   继续量测长路径整页 transfer、复杂对象叠放和内存峰值。
8. `commitOriginalPartialErase()` 改用 Promise 的独立 fulfilled/rejected handler。durable transaction 已成功后，
   即使 Undo/UI 安装抛错，也只记录错误并重新加载当前页，绝不会被下游 `.catch()` 误判为 transaction 失败后
   再执行一次 local replacement。
9. 修正 `StrokeTypes.ets` 的旧注释：tool 5 是 transient partial-eraser preview/兼容语义；完成后的本地 partial
   erase 永久保存的是普通 Ink remnants，而不是 destination-out tool-5 Ink。

## 边修边审额外捕获的问题

- 初始专项 replay 对 `kt1/dh5` 的混淆变量和字符距离约束过窄，误命中同文件较早代码；已改为锁定实际
  `d04.J → PARTIAL_ERASER` 与 `d04.J → jt1` 分支。
- 全量 replay 发现 Phase 237 的旧门禁仍要求 `commitOriginalPartialErase(plan)`；现升级为同时验证
  `partialEraserPreview.finish()` 与 `commitOriginalPartialErase(plan, previewToken)`，防止未来丢失 token 生命周期。
- 复核 durable Promise 时发现旧 `.then(...).catch(...)` 会把 fulfilled handler 内的 UI/history 异常也送入
  transaction fallback，从而可能对已提交的数据二次执行本地替换；本阶段已彻底分流。
- preview 的 destination-out 不能直接落在主画布，否则会连纸张一起挖透明；现仅在 handwriting/content 隔离层
  合成，再恢复背景与前景。

## Fixture 与 replay

- 新增并注册 `OriginalPartialEraserTransientPreview.test.ets`，覆盖：
  - tool-5 preview 从 tracking 保持到 durable completion；
  - stale token 不得清除新手势；
  - 超预算整次失败而非提交截断路径；
  - 非有限坐标、非法宽度和非法预算在渲染前拒绝。
- 新增专项 replay：
  `originalPartialEraserTransientPreview=tool5-memory-preview-dirty-crop-commit-end-cancel-fail-closed`。
- 更新既有 local partial-eraser replay，使其验证 preview token 与 durable replacement 的新接线。
- 全量桌面 replay：`REPLAY_FILES=226 FAILED=0`。
- `git diff --check`：通过；仅有项目既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 3 s 537 ms`。
- clean 后 `note@ohosTest` 非增量 HAP：`OhosTestCompileArkTS` 实际执行，
  `BUILD SUCCESSFUL in 8 s 706 ms`。
- 同一次 clean 后 `note@default` 非增量 HAP：Native Ninja、`CompileArkTS` 与 PackageHap 通过，
  `BUILD SUCCESSFUL in 31 s 282 ms`。

## 决策与文档

- 新增 `ADR-0218-original-partial-eraser-transient-preview.md`，记录非持久 preview、token、dirty crop、
  success/rejection 分流与 transport 边界。
- 新增 `original-partial-eraser-transient-preview-jadx-2026-08-16.md`，固化
  `kt1/bt1/dh5/a5g/fg2/wq9` 原版证据与哈希。
- 新增 `d02-original-partial-eraser-transient-preview.mjs`，把原版调用链、生产接线、fixture、预算和
  fail-closed 门禁纳入持续回归。

## 尚未执行/后续

- 未启动设备、模拟器、虚拟机或 Hypium；本阶段只完成源码修改、桌面 replay 与两套 HAP 编译。
- 真机需集中验证：单点 round-cap、快速长路径、400% zoom、PDF/深色纸张、Text 前后层、Shape/Image/Math
  mixed z-order、提交延迟、取消/换页竞争，以及大页面 OffscreenCanvas 内存峰值。
- 项目仍没有已认证的原版协作 transport consumer 与 incoming transient reducer，因此没有伪造远端 tool-5
  CREATE/ADD/end outbox；远端实时预览仍属于后续同步阶段。
- Goal 保持 active，下一阶段继续按修复总纲与边修边审结果选择高优先级原版差异。
