# ADR-0218：Partial eraser 使用非持久 tool-5 preview，并在 durable replacement 后结束

## 状态

Accepted，2026-08-16。dirty-crop 层级条款已由 ADR-0219 更正。

## 背景

Phase 237–240 已把本地 partial erase 的最终结果修正为 CREATE_INK remnants、Group replacement、
DELETE_ENTITIES sources 与持久 Undo/Redo。但 UI 仍只收集 `eraserPath`，移动期间没有任何擦除反馈；抬手后又
立刻清空路径，必须等数据库事务完成才看到最终结果。若 transaction 较慢，会出现明显空窗；若以后简单地在
pointer-up 清除实时遮罩，还会产生“先擦掉、再闪回、随后又消失”的跳变。

原版 `kt1/bt1` 在 pointer-down 创建 transient tool-5 CREATE_INK，move 追加 ADD_PATH_ELEMENTS；
`dh5 → jt1 → wc` 在 durable replacement 完成后调用 `oqi.a(...)` 结束 interaction，cancel 也只结束 transient。
详细证据见 `original-partial-eraser-transient-preview-jadx-2026-08-16.md`。

## 决策

1. 新增 `OriginalPartialEraserTransientPreview`，状态只允许
   `IDLE → TRACKING → AWAITING_COMMIT → IDLE`。preview 持有非持久 tool-5 `StrokeElementData`、唯一 token、
   路径和边界；不进入 `completedStrokes`、`elementOrder`、snapshot 或 operation log。
2. pointer-down 建立 preview，move 追加去重后的画布点并立即触发渲染；pointer-up 复制同一 center path 给
   Phase 239/240 的原版 boolean eraser，然后把 preview 保持在 `AWAITING_COMMIT`。
3. durable transaction 成功时先清 preview，再安装 transaction 返回的元素与 Group；transaction 明确失败时
   先清 preview，再执行既有 fail-closed snapshot fallback。无命中、非法点、超预算、Cancel、换页和生命周期
   离开都清理 preview，且不产生 durable tool-5 Ink。
4. preview 路径最多 65,535 点。非法点或超预算不允许截断后继续提交，因为“用户看到的路径”和“实际 boolean
   clip 路径”不同会造成不可预测删除；整次手势 fail-closed。
5. 活动 preview 统一使用 `StrokeLayerManager.compositeWithOrderedPartialEraser()`：每个累计 dirty crop 在透明
   离屏层重建完整 Stroke/Text/Shape/Image/Math 顺序，再把 tool-5 Ink 追加到最顶层；Paper 在主画布单独恢复。
6. 不再区分“Stroke→Text 快速路径”和 mixed z-order 路径。后续设备回归需评估长路径时的 transfer、CPU 和
   内存，再决定是否引入可复用 tile preview layer；不得把 Text 固定重画为前景。
7. `commitOriginalPartialErase()` 使用 Promise 的独立 success/rejection handler。durable commit 已成功后，即使
   UI/history 安装抛错，也只重新加载当前页，绝不能被下游 `.catch()` 误认为 transaction 失败并再次执行本地
   replacement。
8. 本阶段不新增 transient 网络 outbox。没有认证 transport consumer 时，生成 CREATE/ADD/end bytes 只会形成
   无人消费或错误持久化的协议假象。远端 preview 仍由后续 incoming transient reducer/transport 任务承接。

## 结果

- partial eraser 从按下开始有即时内容层反馈，提交等待期间不闪回。
- Cancel、双指接管、换页和无命中不会留下 tool-5 Ink 或破坏 Undo。
- preview transfer 与实际脏区一起增长，而不是每帧固定传整页；所有页面类型共享同一有序内容语义。
- durable 成功后的 UI 错误不再触发二次本地删除。
- 真机仍需验证 ArkUI Canvas 的单点 round-cap、快速长路径、400% zoom、混合 z-order 与大页面内存峰值。
