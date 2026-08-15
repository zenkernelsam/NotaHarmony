# Phase 244 修复总结：原版本地笔记背景 `SET_METADATA` 出站

## 本阶段目标

修复纸张尺寸、模板和方向仍被当作当前页 `PAGE_SETTINGS` 的协议分叉。原版 1.0.3 的纸张面板修改的是
笔记级 `pageBackgroundRegister`，因此本阶段让 Harmony 的本地设置、页面 fallback、普通新页、上传 operation
和持久 Undo/Redo 共用同一条原版 `SET_METADATA.pageBackground` 事务链。

## 原版结论

- `uge → l3a → qgh → u5j.H/xj2` 证明纸张 UI 生成 payload type 1 `SET_METADATA`，而不是页面级
  `MODIFY_PAGE.background`。
- `l2d.field1 → m2d.field0 → nz9` 是完整 wire 链；`m2d` 存在但 value 缺省表示明确把寄存器写成 null，
  与整个 setter 缺省的“不修改”不同。
- `l3a` 固定 imperial ×72、A 系列 ×2.83465、模板间距 36 pt、四边 margin 36 pt，并保留既有 PDF、
  crop、rotation 与资产 metadata。
- `fad` 从未旋转的 source size 决定设置面板方向；页面实际宽高仍包含 cardinal rotation。
- `v69/fqb` 把背景作为笔记级 LWW register；page register 为 null 的页面继承该 winner。
- 最终用 APK DEX 的 `vnf.c` 复核逆操作：旧 `a79.K` 即使为 null，也会再次调用 `qgh.b(null)`。
  因此 Undo 不能用视觉等价的具体 Letter 背景替代 nullable register。

完整线性证据见
`docs/migration/evidence/original-local-set-metadata-background-outbound-jadx-2026-08-16.md`。

## 已完成修复

1. 新增 `OriginalSetMetadataPayloadEncoder.ets`，完整写出 `l2d → m2d → nz9`，覆盖 paper、PDF、
   64-byte hash、UTF-8 metadata、crop vector、rotation、source size 与 margins；explicit-null 时保留
   `m2d` table。
2. 新增 `NoteBackgroundSettings`，同时保存供渲染／物化使用的 effective `background` 与原版精确 nullable
   `registerBackground`，并加入严格 clone、校验、比较、原版纸张换算和 source-orientation 推导。
3. 新增 `OriginalNoteBackgroundPersistence.ets`：在共享 editor mutex 与单一 SQLite transaction 中检查完整且
   对齐的原版页面身份、分配 operation identity、包装完整 `uq9`、调用生产
   `OriginalSetMetadataOperationApplier`、验证 winner/materialization/revision，再同时追加待上传 type-1 行与
   NBG history companion；任一步失败均整事务回滚。
4. 生产 reducer 现在可读取 exact register state，并只更新 page-register-null 的 live/archive fallback 页；
   具体页面背景不会被笔记设置覆盖。
5. 新增 `UPDATE_NOTE_BACKGROUND` durable history、NBG1 codec 和 `NOTE_BACKGROUND` runtime action。
   PUSH/UNDO/REDO 每次都生成新的原版 `SET_METADATA`；撤销回初始状态会真正发送 present-wrapper + null-value。
6. `ORIGINAL_SET_METADATA` 加入 `PersistentHistory` 透明 companion 白名单，不再切断本地 Undo 栈。
7. 普通本地 `CREATE_PAGE` 发送 `background=null`，由生产 reducer 读取当前笔记 winner 物化尺寸／模板／方向，
   同时保持 `background_json=NULL`，使新页继续继承后续笔记设置。
8. `PageSettingsPanel → PageManagerBar → NotePage` 改为笔记级设置；页面切换不再改变面板值。页面列表在提交和
   Undo/Redo 后重新读取，选中页按稳定 ID 恢复。
9. 设置面板加入 A7；活动面板颜色走 ThemeTokens，标题、模板和方向文案走资源。
10. 任何已有 original identity 的页面继续走旧 `updatePage/PAGE_SETTINGS` 时都会写前拒绝，避免绕过笔记级
    winner 形成双写状态。

## 边修边审额外捕获的问题

最初实现只保存 effective Letter，因此从首次纸张修改 Undo 时虽然画面恢复为 Letter，数据库和下一条上传
operation 却留下了具体 Letter `nz9`。DEX 对 `vnf.c` 的复核证明原版会读取旧 `a79.K=null` 并调用
`qgh.b(null)`。本阶段据此补回 exact nullable register，并把 explicit-null 的 PUSH/UNDO/REDO、replay 和
ArkTS fixture 一并锁定。

最终复核还追查了继承 PDF 时 `CREATE_PAGE.pageInAsset` 的初始化。`v69` 明确仍按 CREATE payload 内序号（或
payload 自带 PDF offset）建立独立 register，不从笔记 fallback 猜 offset；当前实现保持了这一原版行为，
未引入额外改写。

## Fixture、replay 与构建

- 新增 `OriginalSetMetadataPayloadEncoder.test.ets` 并注册进 `List.test.ets`，覆盖完整背景 round-trip、
  explicit-null、A 系列 Float32、source orientation、PDF/rotation 保留和 NBG1 exact-null history。
- 新增 `d02-local-set-metadata-background-outbound.mjs`；专项输出为
  `localSetMetadata=type1-explicit-null-full-flatbuffer-source-orientation-fallback-create-exact-null-undo-redo-history-transparent-rollback`。
- 相关 replay：`RELATED_REPLAY_FILES=8 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=229 FAILED=0`。
- `git diff --check`：通过；只有工作树既有 LF→CRLF 提示。
- 增量 `note@ohosTest` 与 `note@default` 均构建成功，后者为 `BUILD SUCCESSFUL in 19 s 970 ms`。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 772 ms`。
- clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 7 s 142 ms`；clean 后 `note@default`：
  `BUILD SUCCESSFUL in 44 s 879 ms`。两次都实际执行 ArkTS 编译，default 还完成 Native Ninja 与 HAP 打包；
  输出只有项目既有 exception-handling/deprecated warning 和未配置签名提示。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 决策、边界与后续

- 新增 ADR-0221，更新 ADR-0048、ADR-0049、ADR-0082 与 ADR-0220，固化 note/page 字段边界、nullable
  register、新页继承和 fail-closed 决策。
- mixed identity 或完全 legacy/imported Harmony 笔记暂不伪造原版 `SET_METADATA`；其 identity bootstrap／迁移
  另行设计。在此之前设置写入会明确失败，不能静默退回 Harmony-only `PAGE_SETTINGS`。
- 真机集中验证仍需覆盖：纸张切换、PDF 四种 rotation、连续 Undo/Redo、重开、新页继承、多端 LWW、上传
  ACK／重新下载，以及设置面板 source orientation 与实际页面方向的组合。
- Goal 保持 active，继续边修边补审。
- T-042 APK 版本追踪严格留到整个 Goal 最后。完成时必须建立追踪文档／工具，另写中文 Report 说明建立了
  什么、用途及使用方式，再把入口、阅读顺序和新版 APK decompile/diff 流程归纳到 Wiki、技术文档、API
  文档与新手入门。
