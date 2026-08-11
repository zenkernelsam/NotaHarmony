# Phase 125 修复总结：原版 Styled Text 字符编辑保真

## 原版证据与设计纠错

- 复核原版 `m4c/x01/ra`：富文本样式端点明确使用 `BEFORE`、`AFTER`、`START_OF_DOC`、
  `END_OF_DOC`，绑定的是字符 `SeqId`。在端点处插入时，仅靠当前 style run 的数字 offset 无法判断
  新字符应在样式内还是样式外，因此不能做普通区间平移。
- 原版字符 sibling 排序对 timestamp 使用 Java signed-int 语义。不能给预览随意指定“大时间戳”；
  必须从当前 `max_op_timestamp` 推导 REMOVE/REVIVE 后真正 INSERT 会使用的 identity。

## 已完成修复

- `OriginalLocalTextMutation` 新增无副作用 CRDT 预览：克隆完整字符树，模拟 remove/revive/insert，
  证明 after 正文可物化后，再经既有原版 style/checkbox authority 生成精确字符与段落 runs。
- 新增操作时钟预测，按非空 REMOVE、REVIVE 批次计算 INSERT timestamp；非法 site/clock exhaustion
  安全拒绝，不跨过 `0x80000000` 后仍用错误 sibling 顺序猜测结果。
- `StrokePersistence` 新增只读预览 API：先 flush 同页旧保存，再在 persistence mutex 内核验 live original
  page/Block、byte-exact before snapshot、字符树、style operation、checkbox state 与 before runs。真正保存时
  在事务中重做预览，after runs 必须 byte-exact 相同才进入 Phase 124 writer。
- `TextBlockTool` 支持成对传入精确样式 runs 并深拷贝。`NoteCanvasView` 在替换元素和写 Undo 前等待预览；
  预览失败不再清空样式或排队错误快照。
- 边修边审补齐异步提交竞态：页面 flush 会等待 Text commit 并传播失败；重复提交由 `historyBusy`
  阻止；组件退出延后释放 renderer，直到最终 commit settle；覆盖层 callback 显式处理 Promise 失败。

## 测试与验证

- 扩展 ArkTS fixture：覆盖样式内插入、`BEFORE/AFTER` 精确边界、文档首尾扩展、删除后的 run 收缩、
  hidden identity revive 恢复、paragraph checkbox SeqId 附着、REMOVE 后身份偏移、clock exhaustion，
  以及传入 runs 的深拷贝所有权。
- 新增 `d02-local-styled-text-edit.mjs`，专项输出：
  `localStyledTextEdit=original-seqid-boundaries-insert-delete-revive-paragraph-checkbox-clock-preview-ui-guard-single-revision-rollback`。
- 全量桌面 replay 为 `TOTAL=111 FAILED=0`，`git diff --check` 通过。执行 `hvigorw clean` 后严格
  串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`；只有项目既有
  deprecated/exception-handling warning。未启动模拟器、虚拟机、真机或执行 Hypium。

## 仍待后续

- 本阶段只保证“既有原版样式在字符编辑中不丢失”。本地格式工具尚未发出 type 12/13/14，不能宣称
  字符/段落样式创作已完成。
- Text 空白-only 提交语义、完整原版文本布局/选区、Shape caption RichText 编辑、clipboard/package
  Group 保真、私有 transport/ACK 与集中设备验收仍属于 Goal 后续。
