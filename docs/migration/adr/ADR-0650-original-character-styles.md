# ADR-0650 — 原版字符样式（B/I/U/S）编辑与提交语义

## 状态

Accepted（Phase 684，随实现落地）

## 上下文

原版 `cve.java` 把文本工具条的四个字符样式项派单为 `n(new zyd(...))` 字段级
增量变更（`zyd.a/b/c/k` = bold/italic/underline/strikethrough，其余字段
`null` 表示保持），由编辑器把变更应用到当前选区或光标 typing-attributes。

Harmony 端 Phase 681/683 已建立"段落级 draft 样式 → 提交时折回 run"管线；
字符样式需要**选区级**（而非段落级）编辑，且 `TextBlockTool.updateText`
要求字符 run 与段落 run 同时提供或同时省略。

## 决策

1. **选区语义**：`caretSelectionStart`/`caretOffset` 构成编辑选区；非折叠时
   `applyCharStyle(field, !rangeHasCharStyle(field, s, e), s, e)`——选区被
   `field=true` 的 run **完全覆盖**则置 false，否则置 true（对应原版
   `!br2.x` 取反）。
2. **字段级增量**：`applyCharStyle` 在选区边界切分既有 run，仅改写字段并
   深拷贝保留其余字段；选区空洞补 `{field:value}` 单样式 run——等价于
   原版 `zyd` 的 null=保持语义。
3. **折叠光标 → pending typing-attributes**：`pendingCharStyles` 记录待生效
   字段；`onChange` 经公共前后缀差分定位插入区间，把 pending 字段落地为
   run——对应原版光标态样式对后续输入生效。
4. **run 位置随编辑漂移**：`adjustCharRunsForEdit` 按差分平移/收缩/丢弃
   run，保证 draft run 始终与 `draftText` 对齐。
5. **canonical form**：`normalizeCharRuns` 排序 + 去空段 + 合并相邻同样式
   run，使 `JSON.stringify` diff 稳定。
6. **三参提交**：`onCommit(text, charRuns, paraRuns)` → `onTextCommit`
   三参；各分支以 `authored ?? existing` 独立传递两数组——只 authoring
   一类样式时**不**清空另一类（修复了样式-only 分支原先把未 authored 的
   段落 run 置 `[]` 的隐患）。
7. **`stylesDiffer` 扩展**：字符/段落任一 authored run 与原块序列化不同即
   触发样式级更新；文本不变 + 样式变化仍走样式-only 提交。

## 与原版差异 / 限制

- **pending 不清除时机**：原版 typing-attributes 在光标移动后失效；
  Harmony 端 pending 在折叠光标期间持续（collapsed→collapsed 移动不清除）。
  影响轻微：用户在移动光标后输入仍按 pending 落地，与原版"移动后恢复
  默认"存在可见差异，登记为低危偏差。
- **CRDT 写侧缺口**（沿用 ADR-0648）：本地无 MODIFY_CHARACTER_STYLE
  编码器；CRDT 块文本未变仅字符样式切换时，样式只写元素级并随元素持久化，
  不产生字符样式 CRDT op——同步合并后可能被远端覆盖，与原版可产生
  字符样式 op 的行为存在差异。
- **混合选区指示**：原版 `br2` 对混合选区的展示态未完全解码；Harmony 以
  "完全覆盖才亮"近似——混合选区显示 off，再次点击统一置 true（结果与
  原版一致）。
- **未覆盖项**：superscript/subscript（`kue`/`lue`，zyd.i/j 互斥对）、
  highlight（`rte`，zyd.d）、font family/size/color（zyd.e/f/g）、
  link（`tte`，zyd.h）本期不实现，工具条少于原版完整格式行。
- **suspend 路径**：挂起提交仅携文本（与 P681 段落 draft 一致），未提交的
  pending/draftCharRuns 丢失——与既有段落样式行为对等，非新增偏差。
- **按钮形态**：沿用覆盖层文本按钮样式（非原版图标），与 P681/683 一致。

## 验证

- Replay：`d02-original-character-styles.mjs` TOTAL=34 FAILED=0。
- 受影响既有 fixture 全部更新通过；全量 Replay 套件全绿。
- `note@default` / `note@ohosTest` clean 构建成功，无新增 ArkTS 错误。
