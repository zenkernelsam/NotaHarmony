# Phase 270 修复总结：原版 SET_METADATA 六项独立寄存器

## 1. 基线、范围与纪律

- 正式且唯一可写工程：`C:\HarmonyProject\NotaHarmony`。
- Desktop `C:\Users\Cisco He\Desktop\Notability` 仅作为原版 APK、JADX/decompiled 证据源；本阶段没有在 Desktop
  创建或维护 Harmony 源码工作树。
- 阶段基线：`e68b231 fix(ink): preserve original width interpolation`；`origin/main` 仍为
  `c1be5f0 fix(shape): align original hold lifecycle`。
- Phase 264～266 已现场核验仍完整位于 `c1be5f0`：tree
  `b1a9dd87cde5871fe6f9f0fce58b03418a7e5e08`、`5149fe9..c1be5f0` 三个提交/73 个文件，range `diff --check` 通过。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 2. 重新确认的原版行为

直读原版 1.0.3 `l2d/xj2/rz1/v69/fqb/so5/a79/u5j/tv6/dz0/x82/z5c/yo7/jc5`：

1. SET_METADATA 是八字段 FlatBuffer。field 0/1 为 title/pageBackground wrapper，field 2 为 handwriting
   wrapper，field 3～7 为带 presence 的 align、default family、default size、layout、wrap scalar/string/enum。
2. handwriting wrapper 存在但内部 string 缺席是显式 null；普通 nullable scalar/string 的缺席则是不 patch。
3. 原版校验 template PDF 必须 `pagesConsumed == 1`、font family 最多 30 个 UTF-16 单元、font size `>0`，以及
   `_` 前精确 ISO language prefix。`PAGED/PAGELESS = 0/1`，wrap = `0/1/2`。
4. v69 把八项分别写入八个 register；每个 register 用严格 greater unsigned `(timestamp, siteId)` LWW。
5. a79/u5j 证明六项属于 NoteImpl 持久状态并进入原版快照重建链。完整哈希、行号、源码映射在
   [原版证据](../evidence/original-set-metadata-registers-jadx-2026-08-18.md)。

## 3. 实际修改

### 3.1 值域 policy

新增 `note/src/main/ets/core/model/OriginalNoteMetadataPolicy.ets`：

- 固化 Java `Locale.getISOLanguages()` 的 188 个代码（含 `he/iw`、`id/in`、`yi/ji`），只接受首个 `_` 之前的
  精确小写前缀；
- family 按 UTF-16 `length <= 30`，layout 只收 0/1，wrap 只收 0/1/2；
- font size 采用有限且大于 0 的 Harmony fail-safe。原版 IEEE `NaN/+Infinity` 会绕过 `<=0`，本阶段明确记录这是
  数据完整性加固，不冒充原版 validator 分支；
- decoder 对 handwriting/family 加有限 UTF-8 读取预算，防止恶意 operation 无界分配。

### 3.2 wire decode 与同步 applier

`note/src/main/ets/data/OriginalSetMetadataOperation.ets`：

- 解码 field 2～7，保留每个 scalar 的 vtable presence 和 handwriting explicit null；移除旧的
  `SET_METADATA_FIELDS_UNSUPPORTED`；
- preflight 拒绝非法 language/family/size/layout/wrap、超页 template PDF，并继续校验 title/background；
- 为六项各自读取/写入 winner，逐字段执行严格 greater LWW；stale field no-op，same identity/same value 幂等，
  same identity/different value deferred conflict；
- 先完成所有字段的 conflict decision，再开始任何 winner/materialized 写入；混合 operation 最多推进一次
  `structure_revision`；
- 复核修正 PDF asset 顺序：`mergeOriginalAssetReference()` 只在 background winner 真正获胜后调用，避免 stale
  PDF 或后续 identity conflict 留下已提交资产副作用；
- `readOriginalNoteMetadataState()` 改为单条 LEFT JOIN snapshot 查询，保证六项 readback 不出现跨 SQL 撕裂，并能区分
  handwriting winner 缺席与 winner 值为 null。

### 3.3 数据库与 bootstrap

- `DatabaseHelper.ets` 从 v64 升至 v65，新增六张 `note_id` 主键 winner 表；handwriting value 可 null，其余值域有
  SQLite CHECK，全部 `FOREIGN KEY(note_id) ... ON DELETE CASCADE`；
- `DatabaseManager.ets` 的最新 schema 初始化纳入六张表；
- `OriginalBlankNoteBootstrapPersistence.ets` fresh-note gate 纳入六张表，避免残留 metadata 被误判为空白新笔记。

### 3.4 fixture、Replay 与历史门

- `OriginalNoteMetadataPolicy.test.ets` 覆盖精确 ISO 前缀、UTF-16 family、finite size、enum；并注册到 `List.test.ets`；
- `SyncedOperationInbox.test.ets` 新增八字段 FlatBuffer fixture、explicit-null、scalar presence、非法值和
  `pagesConsumed=2` 拒绝；
- `DatabaseHelper.test.ets` 更新 v65 与六表 DDL/migration 断言；
- `d02-original-element-order-identity.mjs` 的旧 v64 精确门改为 `>=64`；
- 新增 `d02-original-set-metadata-registers.mjs`，覆盖源码、DDL/cascade、独立 LWW、stale/identity conflict、
  原子回滚、stale PDF asset、invalid input、readback、bootstrap 和 fixture 注册；
- 同步更新两条历史 title/background Replay 的过时源码门，使其继续验证当前通用 presence gate 和 winner 命名。

## 4. 验证结果

| 项目 | 结果 |
|---|---|
| Phase 270 专项 Replay | `D02_ORIGINAL_SET_METADATA_REGISTERS_OK TOTAL=36 FAILED=0` |
| 全量 Desktop Replay | `REPLAY_FILES=255 FAILED=0` |
| `git diff --check` | 通过（仅 Windows CRLF 转换提示） |
| 增量 `note@ohosTest` | `BUILD SUCCESSFUL in 6 s 608 ms`（atomic readback 后） |
| 增量 `note@default` | `BUILD SUCCESSFUL in 15 s 202 ms` |
| clean | `BUILD SUCCESSFUL in 1 s 869 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 7 s 445 ms` |
| clean 后 `note@default` | `BUILD SUCCESSFUL in 43 s 803 ms` |

构建输出只有项目既有 ArkTS exception-handling/deprecation 与未配置签名 warning，没有新增 error。`ohosTest` 仅证明
fixture 可编译/打包，不冒充设备运行态 assertions。

## 5. 当前闭环与明确边界

本阶段已闭环：

- SET_METADATA field 2～7 的 wire decode、presence/null 语义、原版值域及 Harmony fail-safe；
- 六个独立 SQL winner、严格 LWW、stale no-op、same-identity integrity conflict；
- 混合 operation 的 conflict-before-write、PDF asset 原子边界、单 revision；
- v65 migration/cascade、重启后持久 readback、blank-note fresh gate；
- 原版源码与 Harmony fixture/Replay 的可审计证据链。

仍开放，不能由本阶段宣称完成：

- PAGELESS 主画布/页管理/缩略图完整 consumer；
- align-to-lines 的 Text block 创建/基线吸附；
- handwriting recognition provider 与无 provider fallback；
- default font family/size 的 CREATE_BLOCK、编辑器继承、本地 UI 和出站 writer；本阶段刻意没有把固定字号 `17` 猜改为
  `defaultFontSize`；
- blockWrapSupport 的文本换行 consumer；
- explicit-null title、真实旧库/多设备同步、保存重启/NOTE_BUNDLE round-trip 与设备像素/性能。

## 6. 总纲与 Goal 纪律

- `修复总纲.md`、`修复总纲2.md` 和 `修复进展-2026-08-09.md` 已补录 Phase 270 与 v65/六表边界；ADR-0048 的旧“六项
  全部 deferred”现场已更正为“入站持久化闭环、consumer 仍开放”。
- T-042 APK 版本追踪继续留到整个 Goal 最后一项；本阶段没有建立版本追踪目录，也没有执行新版 APK 全量 diff。
- Goal 仍保持 active。
