# Phase 105 修复总结：原版本地 CREATE_PAGE 出站身份

## 原版证据

- 原版 `haa` 将 CREATE_PAGE 固定为 payload type 3；`ln2` 的字段依次是 nullable `location`、
  nullable `background`、默认 1 的 `pageCount` 和默认 UNBOOKMARKED 的 bookmark。
- 原版 `haj.a/c()` 使用 FlatBuffer builder 写入同一布局；`cxc` 是
  `site:uint16 + padding + timestamp:uint32 + index:uint32` 的 12-byte SeqId。
- 页面稳定身份来自 CREATE_PAGE operation 的 `(timestamp, siteId, payload index)`；后续插页引用
  当前 position SeqId。页面被 move 后，稳定 page identity 与 winning position 可以不同，不能用
  `page_index` 或随机 UUID 猜 anchor。
- 无显式 `nz9 background` 的原版默认页是 Letter 215.9 x 279.4 mm，不是此前 Harmony 默认 A4。

## 已完成修复

- 新增原版 CREATE_PAGE FlatBuffer writer：默认首页保留 nullable location/background 和 Letter 语义；
  普通空白页通过 `nz9.sourceSize` 精确保留 A4/自定义宽高，不把 A4 静默降成 Letter。
- 新增本地 page persistence helper：事务内分配 operation identity、读取当前尾页 winning position、调用
  已验证的原版 reducer、验证非 deferred、追加 `uploadImmediately=true` 原版 operation，并返回 reducer
  生成的 canonical pageId。
- `NoteRepositoryImpl.createNote()` 不再先造随机 A4 页面和 Harmony-only CREATE_PAGE，而是创建原版默认
  Letter 首页。`NotePage` 在 add 成功后用 canonical ID 同步修正 action、顺序与选中页，避免 Undo 继续引用旧随机 ID。
- 扩展 DELETE_ENTITIES writer 支持 pageDeletes/pageUndeletes。交互式新增页的撤销/重做、删除页的撤销/重做
  复用同一 page SeqId 和原版 reducer 的页面、元素、搜索归档，不再通过新 CREATE_PAGE 换身份。
- 页面写操作改用共享 `editorPersistenceMutex`，与笔迹 snapshot、录音和 inbox 串行；原版 reducer、outbound
  行与本地 NPG history companion 同事务提交，任一环节失败全部回滚。
- 修复边修边审发现的持久 Undo 断层：已知 `ORIGINAL_CREATE_PAGE`、`ORIGINAL_DELETE_ENTITIES`、
  `ORIGINAL_CREATE_RECORDING` 无 history metadata 的 companion 行不再被误判为旧日志 barrier；真正旧格式无 metadata
  行仍保持保守断栈语义。
- 导入器改用显式 `addImportedPage()`，`.note`/旧 Notability 包恢复页面时不制造新的本地原版 authoring op。
- 只有 live page identity 完整且 `page_info` 顺序与原版 CRDT visible order 一致时才走原版路径。旧笔记、混合笔记或
  尚未迁移 reorder 的笔记保守沿用旧路径，不猜 location，也不让新增按钮因 reducer defer 失效。
- 原版 background decoder 现在从实际尺寸推断 Harmony PaperSize；尺寸仍以原始 width/height/sourceSize 为准，未知
  自定义尺寸仅使用 Letter 作为无 CUSTOM enum 时的分类回退。
- 生产接线使此前仅测试可达的 CREATE_PAGE reducer 进入 ArkTS 编译图，顺带修复 `StoredSyncedOperation` 被结构化当作
  缺少 index 的 `OriginalSequenceIdentity` 的潜伏编译错误。

## 验证

- 新增 ArkTS 测试覆盖：原版隐式 Letter 首页、带 SeqId 的 A4 sourceSize round-trip、page delete/undelete vector，
  以及原版 outbound companion 不清空 persistent Undo。
- 专项 replay 输出：`localCreatePage=original-seqid-tail-canonical-visibility-rollback`。
- 全量桌面 replay：`TOTAL=91 FAILED=0`。
- 增量 `note@default` 与 `note@ohosTest` ArkTS/HAP 编译均已通过。执行 `hvigor clean` 后严格串行构建
  `note@ohosTest` 与 `note@default`，两者均为 `BUILD SUCCESSFUL`，只有项目既有 warning。

## 仍待后续

- 本阶段不虚报 MODIFY_PAGE、MODIFY_POSITIONS/reorder、旧笔记 identity bootstrap、带样式纸张/PDF 本地 CREATE_PAGE、
  私有 transport/ACK 已闭环。对不满足身份与顺序前置的笔记仍安全回退，不发送错误原版 op。
- 新创建且顺序对齐的笔记现在已经具备 CREATE_INK 所需 page SeqId；下一阶段仍必须在 touch-down 前分配 CREATE_INK
  operation identity，并用它取代随机 stroke ID，才能避免笔迹双实体。
- 未启动模拟器、虚拟机或真机，未执行设备 Hypium。页面默认尺寸、Undo/Redo、导入隔离和跨端同步仍需明早设备集中验收。
  Goal 保持 active，继续边修边补审。

## Phase 246 修正

本报告“普通 `createNote()` 创建原版默认 Letter 首页”的结论已被更完整的 `id7.d()` 与 APK DEX 证据修正。
原版普通空白新笔记不是单页，而是先写 combined `SET_METADATA(title + selectedDefaultTemplate)`，再写一条
`CREATE_PAGE(location=null, background=null, pageCount=2)`。Phase 246 已让两张初始页共享同一 operation identity
的 index 0/1、继承 note background，并与 note/search/winner/两条上传 op 在一个事务内提交。Phase 105 对后续
交互式单页 CREATE_PAGE、canonical page identity 和 page delete/undelete 的结论继续有效。详见 ADR-0223 与
Phase 246 报告。
