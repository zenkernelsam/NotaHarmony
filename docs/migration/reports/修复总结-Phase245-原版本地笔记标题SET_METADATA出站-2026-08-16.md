# Phase 245 修复总结：原版本地笔记标题 `SET_METADATA` 出站

## 本阶段目标

修复标题编辑仍直接改 `note_meta.title` 的协议分叉，使既有笔记的本地标题修改与原版 1.0.3 一样生成
title-only `SET_METADATA`，并让 title LWW winner、标题物化、搜索索引、更新时间、上传 operation 及
PUSH/UNDO/REDO 在同一条可恢复事务链上保持一致。

## 原版结论

- `de4` 的编辑态最多保留 200 个 Java `String.length()` 单位，即 UTF-16 code units。
- `dp` case 14 只把 exact empty 替换为 `feature_note__default_title`；资源值是 `New Note`，路径不调用
  `trim()`，所以纯空格是合法标题。
- `dhh → xj2 → l2d` 把标题写成 `l2d.field0 → z2d.field0`；正常编辑不携带 field 1，因此缺省背景表示
  “不修改”，不是 explicit-null。
- `l2d.a()` 的 wire 校验接受 1..256 UTF-16 units；UI 200 与同步/reducer 256 是不同边界。
- `v69` 分别合并 `titleRegister` 与 `pageBackgroundRegister`。DEX 中的 `vnf.c()` 证明 Undo 会读取旧标题并
  再生成一条新的 `SET_METADATA.title`，而不是只回写本地列。

完整证据见
`docs/migration/evidence/original-local-set-metadata-title-outbound-jadx-2026-08-16.md`。

## 已完成修复

1. 新增 `OriginalNoteTitlePolicy.ets`：实现 200-unit 编辑上限、256-unit wire 上限、exact-empty
   `New Note`、纯空格保留，并在 200 边界避免制造孤立 surrogate。
2. `OriginalSetMetadataPayloadEncoder.ets` 新增 title-only FlatBuffer writer，严格写出
   `l2d.field0 → z2d.field0`，同时保持 pageBackground 字段缺省；UTF-8 必须 round-trip 且不超过 1024 bytes。
3. `OriginalSetMetadataOperationApplier` 不再把 title-only payload defer；title/background 按字段存在性独立读取
   winner、比较 `(timestamp, site)`、检测相同 identity 冲突并物化，缺省背景不会被误作 explicit-null。
4. 新增 `OriginalNoteTitlePersistence.ets`：在共享 writer 与单一 SQLite transaction 内分配原版 identity、
   调用生产 reducer、验证标题和单次 structure revision、单调更新 `updated_at`，再追加 upload-immediate
   `ORIGINAL_SET_METADATA` 与可选 history companion。搜索标题行由 reducer 同事务更新。
5. 新增 NTL1 `NoteTitleMutationCodec`，明确 `UPDATE_TITLE=30` 只承担 Harmony durable-history companion，
   不上传也不代替原版 operation；`PersistentHistory` 可跨会话恢复 `NOTE_TITLE` action，并把原版上传行视为透明。
6. runtime 增加 `NOTE_TITLE` Undo action；PUSH、UNDO、REDO 每次都调用 `updateNoteTitle()`，从而各自产生新的
   原版 operation identity 与 title winner。
7. `NoteRepositoryImpl.updateNote()` 保留兼容接口但委托原版标题事务，并新增返回 materialized title 的
   `updateNoteTitle()`。
8. `NotePage` 统一 commit policy，串行化 onSubmit、onBlur、返回与 teardown；generation 防止旧保存覆盖新 draft，
   队列在异常后仍可继续。返回还会等待 submit/blur 已启动的在途事务，避免路由先退出。
9. 标题数据库已提交后若 runtime Undo 栈 push 发生竞态错误，界面不再回滚到旧标题；错误会单独记录，持久
   history companion 仍可在重开时恢复，避免“界面旧、数据库新”。
10. 新建笔记默认标题从 `Untitled Note` 对齐为 `New Note`，中英文占位资源同步为 `New Note`／`新笔记`。

## 边修边审额外捕获的问题

- 旧 reducer 虽能 decode title，却强制要求 pageBackground；若只放开 preflight，apply 又会把缺省背景当作
  explicit-null。此次按字段存在性拆开整个 merge/materialization 链，避免每次改标题都重置纸张。
- 初版串行队列只覆盖 submit/blur 的相互竞态，但标题编辑器隐藏后立即返回仍可能不等待已经在途的事务；返回
  现始终等待当前队列尾。
- 初版把 `pushPageAction()` 放在数据库提交同一个 catch 中。若 post-commit runtime push 抛错，会恢复旧 UI，
  但数据库和重开结果已经是新标题；现已拆分为“持久化失败才回滚”与“提交后历史同步只记录错误”。
- `zm7` 证明新笔记 builder 可以组合 title/background，但尚不足以确定完整 bootstrap 顺序、初始背景来源和
  失败补偿。本阶段没有据单行证据草率改写创建链，留给紧接的 Phase 继续追证。

## Fixture、replay 与构建

- ArkTS fixture 覆盖 title-only FlatBuffer、中文/emoji、200/256、exact-empty、纯空格、surrogate 边界、
  NTL1 round-trip，以及 `PersistentHistory` 在原版上传行之后恢复标题动作。
- 新增 `d02-local-set-metadata-title-outbound.mjs`，覆盖原版源码契约、独立 FlatBuffer 解析、title/background
  独立 LWW、搜索、单调时间、PUSH/UNDO/REDO、history transparency、identity conflict、stale no-op、
  transaction rollback、返回等待队列及 post-commit UI 边界。
- 原先划定的 9 个相关 replay 均通过；最终全量桌面 replay：`REPLAY_FILES=230 FAILED=0`。
- `git diff --check` 通过；只有工作树既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 728 ms`。
- clean 后 `note@ohosTest assembleHap`：`BUILD SUCCESSFUL in 6 s 930 ms`，实际执行 ArkTS 编译与 HAP 打包。
- clean 后 `note@default assembleHap`：`BUILD SUCCESSFUL in 45 s 155 ms`，完成 ArkTS、Native Ninja 与 HAP
  打包；输出只有项目既有 exception-handling/deprecated warning 和未配置签名提示。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 决策、边界与后续

- 新增 ADR-0222，并更新 ADR-0048、ADR-0182 与两份修复总纲，固化 title-only 字段边界、事务、LWW、
  Undo/Redo 和 UI 竞态决策。
- 真机集中验收仍需覆盖中文/emoji、纯空格、快速 submit+blur、返回手势、失败后重试、连续 Undo/Redo、杀进程
  重开、搜索与最近修改排序、多端 title LWW、上传 ACK 及重新下载。
- Goal 保持 active；下一阶段优先追完整新笔记 combined title/background bootstrap 调用链。
- T-042 APK 版本追踪严格留到整个 Goal 最后。完成时单独建立追踪文档／工具，并另写中文 Report 明确说明
  建立了什么、各自功能及使用方法；随后把它归纳进 Wiki、技术/API 文档和新手入门，明确入口、适用场景、
  阅读顺序，以及新版 APK 的接收、哈希、decompile、语义 diff 与任务映射流程。

## Phase 246 Follow-up

本报告末尾保留的新笔记 combined bootstrap 已在 Phase 246 闭环。完整 `id7.d()`/DEX 证明初始列表依次为
combined `SET_METADATA(title + selectedDefaultTemplate)` 与 `CREATE_PAGE(pageCount=2)`；默认模板来自 root
`nz9` 二进制偏好。Phase 245 的 title-only 编辑、200/256 上限、独立 LWW 与持久 Undo/Redo 结论不变，不能把
combined writer 回用于普通既有标题修改。详见 ADR-0223、Phase 246 evidence 与报告。
