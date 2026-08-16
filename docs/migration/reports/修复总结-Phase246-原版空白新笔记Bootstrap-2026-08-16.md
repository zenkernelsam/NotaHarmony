# Phase 246 修复总结：原版空白新笔记 Bootstrap

## 本阶段目标

闭环 Phase 245 留下的新笔记创建缺口：严格按原版 1.0.3 恢复普通空白新笔记的 combined metadata、
默认模板偏好和两页 CREATE_PAGE，使新笔记从创建开始就具备正确标题、背景、页面身份、搜索和待上传 op。

## 原版硬结论

- `id7.d()` 创建长度为 2 的 operation 数组，顺序是 `id7.h(title)` 后
  `haj.a(null, null, 2, null, 27)`。
- `id7.h()` 从 `noteEditorSettings.selectedDefaultTemplate` 读取 `l3a`，生成同一条
  `SET_METADATA(title + concrete pageBackground)`。
- 第二条 `CREATE_PAGE` 的 location/background 都为 null，`pageCount=2`，所以两张页面继承 note background。
- `pq1 case 5` 按 List 顺序追加；`oq1` 要求创建列表同时存在正 pageCount CREATE_PAGE、SET_METADATA 与
  非空 title setter。
- `selectedDefaultTemplate` 是 root `nz9` FlatBuffer `byte[]`，不是 JSON；内建回退为 Letter / Plain。

完整证据见
`docs/migration/evidence/original-blank-note-bootstrap-jadx-dex-2026-08-16.md`。

## 已完成修复

1. 新增 `OriginalDefaultTemplate.ets`，建立原版默认模板选择与 concrete paper-only background 的转换；
   默认 Letter / Plain，应用时使用标准 source size、零 rotation 与 36 pt 四边距。
2. 新增 `OriginalDefaultTemplateCodec.ets`，直接编码/解析 root `nz9`；Preferences 使用 `Uint8Array`，不再引入
   Harmony-only JSON 格式。
3. `EditorSettingsStore` 对齐原版 store/key，支持读取和保存默认纸张；类型错误删除 key，损坏/截断字节回退
   但不擅自清除，flush 失败执行内存/持久状态补偿。
4. `OriginalSetMetadataPayloadEncoder` 新增 root background writer 和 combined title/background writer，首条
   bootstrap operation 同时携带 `l2d.field0` 与 `field1`。
5. `OriginalCreatePagePayloadEncoder` 支持非默认 `pageCount`，并保持普通单页调用的缺省字段兼容。
6. `OriginalPagePersistence` 新增页面组持久化入口，一次 reducer 调用读取并返回同一 CREATE_PAGE identity 下
   index 0、1 的 canonical 页面。
7. 新增 `OriginalBlankNoteBootstrapPersistence.ets`，在调用方持有的单一 transaction 内严格执行 combined
   SET_METADATA → CREATE_PAGE(2)，验证两个 winner、搜索行、两页继承、identity、operation 顺序、
   upload-immediate、无 history metadata 与最终 `structure_revision=2`。
8. `NoteRepositoryImpl.createNote()` 不再创建单张默认首页；它先解析默认模板，再把 note insert 与完整
   bootstrap 放入同一事务，任一步失败整篇笔记回滚。
9. `LibraryPage` 注入 `EditorSettingsStore`；`PageSettingsPanel/PageManagerBar/NotePage` 接入“设为默认纸张”
   原版动作，并在成功后给出提示。
10. `NotePage` 的 legacy 零页恢复从错误 A4 改为 Letter；正常新笔记在编辑器打开前已有两页。
11. 无法识别内容结构的 partial import 现在回报两张已恢复空白页，不再硬编码 1。

## 边修边审额外捕获的问题

- 初版曾把 `selectedDefaultTemplate` 当成 JSON。第二轮复核 `ss8 case 7` 与 `o59.h()` 后确认其真实格式是
  little-endian root `nz9` `byte[]`，现已改为 Preferences `Uint8Array`。
- 初版二进制 codec 只保留 size/template/orientation。继续复核 `s3a/gq0/l3a.a()` 后发现原版还保存纸张
  RGBA、flair spacing 和 legacy paper index；现已加入语义 round-trip，同时按 mask 7 去除 PDF/rotation。
- 旧零页补偿仍写 A4，会让 legacy/corrupt 笔记与原版 Letter 回退分叉；现已修正。
- importer 的“无法识别内容，仅恢复标题”路径复用普通 `createNote()` 后实际会得到两页，旧回报仍写 1；
  现改为共享 `ORIGINAL_BLANK_NOTE_PAGE_COUNT`。

## Fixture、replay 与构建

- 新增 ArkTS fixture，覆盖两页常量、Letter / Plain concrete background、combined metadata、pageCount=2、
  root `nz9` 二进制 round-trip、RGBA/spacing/legacy index 和损坏偏好拒绝。
- 新增 `d02-original-blank-note-bootstrap.mjs`，覆盖原版源码/DEX、wire 字段、生产接线、事务顺序、
  两页 materialization 和 after-metadata/after-first-page/before-create-op 三处故障的整笔记回滚。
- Phase 246 专项 replay：`blankNoteBootstrap=combined-set-metadata-then-two-page-create-selected-default-rollback`。
- 最终全量桌面 replay：`REPLAY_FILES=231 FAILED=0`。
- `git diff --check` 通过；只有工作树既有 LF→CRLF 提示。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 3 s 461 ms`。
- clean 后 `note@ohosTest assembleHap`：`BUILD SUCCESSFUL in 9 s 88 ms`，实际重新执行 ArkTS 编译与 HAP 打包。
- clean 后 `note@default assembleHap`：`BUILD SUCCESSFUL in 46 s 64 ms`，完成 ArkTS、Native Ninja 与 HAP
  打包；输出只有项目既有 exception-handling/deprecated warning 和未配置签名提示。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 决策、边界与后续

- 新增 ADR-0223，并对 ADR-0003、ADR-0082、ADR-0222、Phase 105/245 历史记录追加 correction/follow-up；
  不机械改写旧阶段当时的验证数字。
- 真机需集中验证：新建后直接显示两页、切页/删除边界、默认纸张跨重启生效、颜色/格线、快速连续新建、
  创建失败无残留、搜索与最近修改排序，以及上传 ACK/重新下载后的 op 顺序和背景继承。
- Goal 保持 active，继续按原版代码边修边补审。
- T-042 APK 版本追踪严格留到整个 Goal 最后。届时单独建立追踪文档／工具并另写中文 Report，说明建立了
  什么、功能和使用方法；随后归纳进 Wiki、技术/API 文档和新手入门，明确用途、入口、使用时机，以及新版
  APK 接收、哈希、decompile、语义 diff 与任务映射流程。
