# Phase 242 修复总结：原版 Partial Eraser 预览层级与有序脏区

## 本阶段目标

继续复核 Phase 241 的 transient tool-5 preview。重点闭环原版 CREATE_INK 的 z-index 来源、页面实体排序方向与
tile renderer 的跨类型绘制顺序，并修正 Harmony 普通 Stroke→Text 快速路径把 Text 无条件重画为前景的逻辑
错误；同时保留 dirty-region 性能边界和 Paper 安全。

## 原版结论

- `kt1 → bt1` 创建的是 transient `u16.PARTIAL_ERASER` Ink。
- 本地 transaction 通过 `fsi.s(..., System.currentTimeMillis(), ...)` 为 operation 写入当前 clientTime；
  `xq9.a()` 把该值传给 CREATE_INK operation。
- `s06.g()` 在没有显式 Ink z-index register 时，使用 payload Realtime，或回退到 CREATE operation clientTime。
- `vnd.compareTo()` 按 z-index unsigned 升序排列；`aa6.t()` 对 bottom-highlight 与普通内容分别排序。
- tool-5 不是 Highlighter，属于普通内容；新 transient Ink 位于既有页面实体之后。
- JADX fallback 的 `aeg.invokeSuspend()` 证明普通有序流同时包含 Ink、Shape、Image、Text 与 Math，并按顺序生成
  交错 draw command；不存在“Text 永久固定在 eraser preview 前景”的原版分层。

完整证据见
`docs/migration/evidence/original-partial-eraser-preview-z-order-jadx-2026-08-16.md`。

## 已完成修复

1. `materializePageElements()` 新增可选 `transientTopStroke`，只在本次渲染数组末尾追加 tool-5 preview；不修改
   durable `elementOrder`、snapshot、operation log 或 Undo/Redo。
2. `NoteCanvasView.renderFrame()` 只要检测到 preview，就统一调用
   `compositeWithOrderedPartialEraser()`；删除 handwriting-only/Text-foreground 分流。
3. 每个累计 dirty crop 使用透明 OffscreenCanvas 重绘完整 Stroke/Text/Shape/Image/Math 顺序，最后绘制 preview。
   因此 Text/Image/Math 位于 tool-5 下方时，会像原版一样暂时显示纸色擦除反馈。
4. Paper/background 仍在主画布 crop 上独立恢复，destination-out 不会把页面背景或 PDF 外层画布挖透明。
5. 保留 pixel-aligned dirty crop 与 `ISOLATED_MASK` transfer 计量；每次 Move 不固定生成整页 bitmap。
6. `forceFull` 时仍先清空整个 viewport，再对整页内容执行有序 crop，避免滚动或缩放时残留旧 transform 像素。
7. 新路径的主 Canvas 与 crop render context 都用 `try/finally` 对称恢复；任一 renderer 抛错不会泄漏
   save/clip/transform 状态。
8. 清理 preview 已被优先分支消费后的不可达条件，durable compatibility tool-5 继续走原有完整有序内容层。
9. 更正 ADR-0218、Phase 241 Report 与 lifecycle evidence，明确早期 Text 固定前景推断已被 Phase 242 废止。

## 边修边审额外捕获的问题

- 不能把 `wq9/xgb` 中的 audioTime 名称直接当作唯一层级字段；真正排序入口是 `s06.g()`，它把显式
  Realtime 与 operation clientTime 统一成 z-index。此次沿完整链路复核，避免仅凭混淆变量名下结论。
- 全量 replay 捕获 `d02-shape-rich-text-consumer-boundary.mjs` 把私有函数签名锁得过窄；新增可选 transient
  参数后产生误报。现改为验证核心 renderContext 与 transient 参数，而不依赖旧的精确右括号位置。
- Phase 241 的专项 replay 仍要求旧 `compositeWithPartialEraser()` 和 Text foreground callback；已升级为验证
  ordered dirty crop，防止错误优化被持续测试反向保护。

## Fixture 与 replay

- 扩展 `PageElementOrder.test.ets`：构造 Stroke/Text/Shape/Image/Math mixed order，断言 transient
  partial-eraser Ink 始终成为最后一个渲染元素，同时 durable order 长度和成员完全不变。
- 新增专项 replay：
  `originalPartialEraserPreviewZOrder=client-time-top-ordered-dirty-crop-all-content-paper-safe`。
- 更新 Phase 241 replay：
  `originalPartialEraserTransientPreview=tool5-memory-preview-ordered-dirty-crop-commit-end-cancel-fail-closed`。
- local partial-eraser 专项 replay：通过。
- 全量桌面 replay：`REPLAY_FILES=227 FAILED=0`。

## 构建与静态验证

- `git diff --check`：通过；仅有项目既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 2 s 64 ms`。
- clean 后 `note@ohosTest` 非增量 HAP：`OhosTestCompileArkTS` 实际执行，
  `BUILD SUCCESSFUL in 8 s 455 ms`。
- 同一次 clean 后 `note@default` 非增量 HAP：Native Ninja、`CompileArkTS` 与 PackageHap 通过，
  `BUILD SUCCESSFUL in 54 s 113 ms`；输出只有项目既有 deprecated/exception-handling warning。
- 最终不可达条件清理后再次编译：`note@ohosTest` 为 `BUILD SUCCESSFUL in 7 s 972 ms`，
  `note@default` 为 `BUILD SUCCESSFUL in 18 s 81 ms`。

## 决策与文档

- 新增 `ADR-0219-original-partial-eraser-preview-z-order.md`，固化“最新 transient Ink + 完整有序 dirty crop”
  决策。
- 新增 `original-partial-eraser-preview-z-order-jadx-2026-08-16.md`，记录
  `n1d/fsi/xq9/s06/vnd/aa6/aeg` 证据、fallback 摘录与 SHA-256。
- 新增 `d02-original-partial-eraser-preview-z-order.mjs`，把原版排序链、Harmony 接线、fixture、Paper 安全和
  crop 资源收尾纳入持续回归。

## 尚未执行/后续

- 未启动设备、模拟器、虚拟机或 Hypium。
- 真机需集中验证：Stroke→Text、Text→Stroke、Image/Math/Shape 交错路径、PDF/深色纸张、单点 round-cap、
  快速长路径、400% zoom、提交等待与取消竞争，以及超大页面 dirty crop 的 CPU/内存峰值。
- 若设备数据显示复杂页面重绘成本过高，后续应按原版 tile renderer 引入可复用内容 tile cache；不得恢复
  handwriting-only/Text 固定前景的错误语义。
- Goal 保持 active，下一阶段继续从修复总纲与边修边审结果选择高优先级静态可闭环缺口；APK 版本追踪仍按
  约定留在最终阶段，并单独写 Report 后集成到 Wiki／技术文档／API／新手入门。
