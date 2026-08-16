# ADR-0223：按原版恢复空白新笔记 Bootstrap

## 状态

Accepted，2026-08-16。

## 背景

Phase 105 曾把普通新笔记实现为一条默认首页 `CREATE_PAGE`；Phase 244/245 又分别补齐 note-level
背景和 title-only 编辑，但创建路径仍没有闭环。原版 1.0.3 的 `id7.d()` 与 DEX 明确表明普通空白新笔记
由有序的两个 operation 构成：combined `SET_METADATA(title + selectedDefaultTemplate)`，随后是
`CREATE_PAGE(location=null, background=null, pageCount=2)`。

继续让编辑器在打开后补默认页会产生可见单页闪变、创建中断留下半笔记、搜索/title/background winner 与页面
不同步，以及跨端收到错误初始 operation 的风险。另一个边修边审问题是 Android 的
`selectedDefaultTemplate` 是 root `nz9` FlatBuffer `byte[]`，并保留颜色、spacing 与 legacy paper index；
使用 JSON 或只保留三个 enum 都不等价。

## 决策

1. `EditorSettingsStore` 在原版 store/key `noteEditorSettings/selectedDefaultTemplate` 下使用 Preferences
   `Uint8Array` 保存 root `nz9` FlatBuffer。类型错误删除该 key；malformed/truncated bytes 回退 Letter / Plain，
   但保留原字节供诊断。
2. 默认模板语义保留 size、orientation、paper flair、spacing、RGBA 与 legacy paper index。应用时按
   `l3a.a(mask=7)` 归一化：去除 PDF/旧 rotation，使用标准 source size、零 rotation、paper-only 背景与
   36 pt 四边距。
3. `NoteRepositoryImpl.createNote()` 在开启 SQLite transaction 前解析默认模板；读取失败安全回退原版内建
   Letter / Plain，不让偏好存储故障阻止用户创建笔记。
4. 同一外层 transaction 内依次完成：插入 `note_meta`；分配 metadata identity；写 combined title/background
   `SET_METADATA`；由生产 reducer 物化 title winner、background winner、搜索行与 structure revision；追加
   upload-immediate metadata operation；写 `CREATE_PAGE(pageCount=2)`；由生产 reducer 创建两张 canonical 页；
   追加 upload-immediate create operation；最后提交。
5. 两条 operation 都不携带 Harmony history metadata。创建 bootstrap 不是用户可撤销动作，也不应伪装成
   NPG/NTL history companion。
6. 两张页面的稳定身份分别是 CREATE_PAGE identity 的 index 0、1；页面自己的 background register 保持 null，
   通过 note-level winner 继承所选默认模板。最终 `structure_revision=2`。
7. 默认模板由 Settings 下独立 `TemplateRoute` 对应页面保存；编辑器 `PageSettingsPanel` 只改当前笔记，
   不得写 `selectedDefaultTemplate`。此入口所有权由 Phase 247 / ADR-0224 更正并闭环。
8. `NotePage` 的零页分支只保留为 legacy/corrupt 恢复，并改用 Letter。普通新笔记在路由进入编辑器前已原子
   完成两页创建。无法识别内容包的 partial import 回报也同步为两张恢复页。

## 结果

- 新笔记不再经历 INSERT note、打开编辑器、补一页的分裂生命周期。
- 初始标题、搜索、默认背景、两页 CRDT identity 与待上传 operation 共享同一提交/回滚边界。
- 原版 List 顺序得到保留：combined metadata 永远先于两页 CREATE_PAGE。
- 默认模板偏好与 Android 同为二进制 root `nz9`，并保留原版可表达的纸张细节。
- 任一 reducer defer、identity/clock、搜索、页面物化或 operation append 失败都会回滚整篇新笔记。

## 被拒绝的方案

- 继续创建一张默认页：与 `id7.d()` 的显式 `pageCount=2` 冲突。
- 两次各写一条 `CREATE_PAGE(pageCount=1)`：会改变 operation identity、组内 index 与原版列表结构。
- 把背景写到每张页面：原版第二条 operation 的 background 为 null，应继承 note winner。
- 先插笔记，进入编辑器后补页：无法满足 `oq1` 对创建 operation 集的要求，也会留下半成品。
- 把默认模板保存为 JSON：破坏原版 root `nz9` 字节契约。
- 只保存 size/template/orientation：会丢失颜色、spacing 与 legacy paper index。
- 为 bootstrap 写 NPG/NTL history：创建不是可撤销编辑动作，且原版初始列表没有 Harmony companion。

## 验证与后续

- 原版线性证据见
  `docs/migration/evidence/original-blank-note-bootstrap-jadx-dex-2026-08-16.md`。
- ArkTS fixture 覆盖两页常量、Letter / Plain 回退、combined metadata、pageCount=2，以及默认模板二进制
  round-trip、纸张颜色/spacing/legacy index 与损坏 root 拒绝。
- `d02-original-blank-note-bootstrap.mjs` 覆盖 JADX/DEX 契约、operation 顺序、root binary preference、
  两页继承、canonical index、structure revision 与多处注入失败的整笔记回滚。
- 最终全量桌面 replay 为 `REPLAY_FILES=231 FAILED=0`；clean 后 `note@ohosTest` 与 `note@default` HAP
  均成功构建。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium；真实路由、双页 UI、偏好持久化和私有同步仍留给集中设备验收。

## Phase 247 后续更正

Phase 246 的 storage/wire/bootstrap 决策不变，但当时把“设为默认纸张”临时接进编辑器 popup 的 UI 位置不符合
原版。原版由设置页 `TemplateRoute/rge` 写偏好，编辑器 `vge` 只写当前 note background。修复见 ADR-0224。
