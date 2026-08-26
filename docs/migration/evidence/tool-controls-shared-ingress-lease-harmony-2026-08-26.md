# Harmony Evidence — 工具颜色粗细共享照片导入租约

日期：2026-08-26
阶段：Phase 485
结论：通过（静态验证）

## 代码证据

- `ColorPicker.ets`
  - 色格保留 `.enabled(!photoImportLeaseActive)`；点击回调再次拒绝该租约后才进入选中或
    普通笔刷分支。
  - 颜色预设数组、选中高亮、主题解析和父页回调绑定不变。
- `WidthSlider.ets`
  - 滑杆保留 `.enabled(!photoImportLeaseActive)`；`onChange` 再次拒绝该租约后才计算宽度档位。
  - 选中范围、步进、普通笔刷范围和父页回调绑定不变。
- `EditorToolbar` 显式传入共享导入租约；`NotePage` 对 `onSelectionColor` /
  `onSelectionWidth` 保留页面操作、历史挂起和结构租约第二层防线。

## 静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-tool-controls-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=11 FAILED=0`。
- 相邻 Replay：工具直改、面板开关、按钮一致化、选中样式上下文通过。
- ArkTS：`ColorPicker.ets` 与 `WidthSlider.ets` 无错误；仅既有弃用 API 信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （35.912 秒）。
- clean：3.544 秒；ohosTest HAP：11.218 秒；default HAP：34.746 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。

---

日期：2026-08-26
阶段：Phase 494
结论：通过（静态验证）

## 增量代码证据

- `EditorToolbar.ets`
  - 自由手/矩形切换按钮回调在调用 `viewModel.setSelectionIsFreehand()` 前拒绝
    `photoImportLeaseActive`。
  - `.enabled()` 继续检查工具加载状态与共享导入租约；按钮标签与 Taper 可用性逻辑不变。
  - 工具状态的乐观更新、持久化事务、版本检查和失败恢复不变。

## 增量静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-direct-mutations-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=13 FAILED=0`。
- 相邻 Replay：选中样式共享租约与本地选中样式通过。
- ArkTS：`EditorToolbar.ets` 无错误，仅既有警告与信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （32.290 秒）。
- clean：3.498 秒；ohosTest HAP：10.298 秒；default HAP：30.731 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。

---

日期：2026-08-26
阶段：Phase 493
结论：通过（静态验证）

## 增量代码证据

- `EditorToolbar.ets`
  - 非紧凑 Photo 与 Math 插入按钮回调先拒绝 `photoImportLeaseActive`，再分别转发
    `onInsertPhotos()` / `onInsertMath()`。
  - `.enabled()` 继续检查工具加载状态与共享导入租约；紧凑菜单已有回调防线不变。
  - 父页共享导入、页面操作、历史挂起和结构租约防线不变。

## 增量静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-builders-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=6 FAILED=0`。
- 相邻 Replay：工具直改、面板开关、按钮一致化通过。
- ArkTS：`EditorToolbar.ets` 无错误，仅既有警告与信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （33.131 秒）。
- clean：3.338 秒；ohosTest HAP：11.084 秒；default HAP：31.320 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。

---

日期：2026-08-26
阶段：Phase 491
结论：通过（静态验证）

## 增量代码证据

- `EditorToolbar.ets`
  - `SelectionStyleButton` 点击回调在转发 `onSelectionStyle()` 前拒绝
    `photoImportLeaseActive`。
  - `.enabled()` 继续检查工具加载状态、共享导入租约和 Taper 变量样式可用性。
  - 父页共享导入/页面操作/历史挂起/结构租约防线以及画布信号消费顺序不变。

## 增量静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-direct-mutations-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=12 FAILED=0`。
- 相邻 Replay：选中样式共享租约与选中样式工具栏上下文通过。
- ArkTS：`EditorToolbar.ets` 无错误，仅既有警告与信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （32.380 秒）。
- clean：3.258 秒；ohosTest HAP：10.489 秒；default HAP：31.526 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。

---

日期：2026-08-26
阶段：Phase 487
结论：通过（静态验证）

## 增量代码证据

- `TextBlockOverlay.ets`
  - 文本框 `onChange()` 在更新草稿和发布父页预览前拒绝共享导入租约。
  - 完成 `onClick()` 在读取并提交当前草稿前拒绝该租约。
  - 取消 `onClick()` 在清空草稿并退出编辑前拒绝该租约。
  - 响应式禁用、父页共享/历史双层防线、宽度自适应预览、确认事务、撤销语义和失败恢复不变。

## 增量静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=13 FAILED=0`。
- 相邻 Replay：文本提交与文本取消通过。
- ArkTS：`TextBlockOverlay.ets` 无错误，仅既有弃用 API 信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （30.769 秒）。
- clean：3.251 秒；ohosTest HAP：9.892 秒；default HAP：30.076 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
