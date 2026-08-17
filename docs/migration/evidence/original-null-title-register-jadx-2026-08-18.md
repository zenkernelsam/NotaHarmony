# 原版 SET_METADATA 显式 null title 寄存器证据（2026-08-18）

## 1. 证据范围与只读基准

本阶段只读原版 Android Notability 1.0.3 反编译树：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`。
Desktop 目录没有创建或维护 Harmony 源码工作树；所有实现和 fixture 均在
`C:\HarmonyProject\NotaHarmony`。

| 原版文件 | SHA-256 | 本阶段用途 |
|---|---|---|
| `sources/defpackage/l2d.java` | `59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8` | title validator 的 null 分支 |
| `sources/defpackage/z2d.java` | `B65ADB097BD4621A054BACDFA94706DDB015AA8473F24149E0F7E6390553CA3E` | SetString nullable accessor |
| `sources/defpackage/rz1.java` | `99B3433644F2BDCFC139EB96FDEEB120F7A87A5BDA693D066DE905116B9E2A86` | wrapper presence 与 register 写入 |
| `sources/defpackage/v69.java` | `69A28ACDF6B65139405E3F22B2EF42AC3DC8FF4E3D8054438EC54B745FE315EF` | titleRegister 接线 |
| `sources/defpackage/a79.java` | `FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13` | NoteImpl nullable title accessor |
| `sources/defpackage/dhh.java` | `393843AF7454BDEF6DD8A4B06679CDD6548E3296183944A89F9521E8A680B900` | null wrapper encoder |
| `sources/defpackage/u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | snapshot 重建 |
| `sources/defpackage/m09.java` | `3B6E92A54E7A5F15BB450A8B89A0A62ED25F2882D65F159595303CD29B6B214A` | NOTE_BUNDLE metadata 初始化 |
| `sources/defpackage/cl9.java` | `27A0769860959CEA5E66FF664B8F2230C29392A9D5D02F5E82AFC1B16741B765` | 导入显示投影 |
| `sources/defpackage/ft0.java` | `13357814742EE3E4111B4C073BDF681D5111E65F8514E120238A31ED694C38AD` | winning SQL NULL 聚合 |
| `sources/defpackage/e47.java` | `54F175BFB7A5C881A46166D241E26668278539C317D075C9BDEE6D6A79BA8467` | Room nullable title DDL |

既有 title 出站/Undo DEX 证据文件（用于 `vnf.c()` 的 APK 本体反汇编结果）：
`docs/migration/evidence/original-local-set-metadata-title-outbound-jadx-2026-08-16.md`，
SHA-256 `AFF1B0209B8D0C1EC246C0489F34B5C9BB76BC16B3E0E05AC7EF7C5D333032CA`。

## 2. wrapper 存在但内部 string 缺席是合法 title register value

- `l2d.java:16-24` 先取得 `z2dVarQ = q()`，只有 `z2dVarQ.j()` 非 null 时才检查空字符串和 256
  UTF-16 code-unit 上限。因此 wrapper 存在、inner value 为 null 不会触发错误。
- `z2d.java:25-30` 的 `j()` 在 vtable field 4 缺席时返回 null。
- `rz1.java:246-251` 的 `O(...)` 只在 wrapper 自身为 null 时跳过；wrapper 存在就无条件把 `z2dVar.j()`
  （包括 null）送入 title register builder。field 缺席与 wrapper-null 不是同一件事。
- `v69.java:1161-1164` 将 `l2d.q()` 单独送入 `titleRegister`，与 pageBackgroundRegister 分离。

因此 title field 有三种状态：

1. `l2d.field0` 缺席：不 patch title register；
2. `l2d.field0` 存在、`z2d.field0` 缺席：winning register 明确为 null；
3. 两层 field 都存在并有字符串：winning register 为 1～256 code units 的 concrete title。

## 3. null 不应被伪装成默认标题

- `a79.java:173-175` 的 title accessor 返回可空 `String`。
- `dhh.java:14-27` 在 `str == null` 时令 inner string offset 为 0，仍建立一字段 `z2d` wrapper；
  `dhh.java:133-153` 的 serializer 同样在 inner null 时保留 wrapper、只省略内部 string。
- `u5j.java:366-380` 从 NoteImpl title register 取值后再次调用 `dhh.a(strF)`，说明 snapshot/rebuild
  链保留 register 的 nullable 语义。
- `m09.java:45-53` 从最新 SET_METADATA 读取 `z2dVarQ.j()`，可把 null 继续传入 metadata state。
- `cl9.java:255-320` 在导入没有有效外部标题时最终把显示值投影为 `""`；没有把它替换成 `New Note`。
- `ft0.java:37-48` 的聚合 SQL 在没有更高 client title 时直接保留 `som.title`，所以 winning SQL NULL
  不会被 CASE 偷换成默认文本。

Harmony 因 `note_meta.title` 和 `search_item.folded_text` 是现有非 NULL 查询契约，采用明确的双层状态：

- `original_note_title_winner.title` 保留真实 `string | null` register；
- `note_meta.title`、标题搜索索引使用 `null -> ""` 的有效显示投影；
- 不写 `New Note`，也不把 null 当成“字段缺席”。

## 4. Undo/Redo 与出站 operation

既有 APK 本体 DEX 证据（见上方 title evidence）显示，`SET_METADATA` 逆操作从修改前的 `a79.f()` 读取
旧标题，再通过 `dhh.a(String)` 和 `u5j.H()` 生成新的 `l2d SET_METADATA`；这条链也覆盖 nullable old
register。Harmony 因此不能只保存 materialized 空字符串：

- v66 迁移重建 title winner 表，允许 SQL NULL 并保留既有 concrete rows；
- local persistence 同时读取 winner row presence、nullable winner value、materialized projection 和
  structure revision；
- 本地编辑仍只接受 concrete 1～256 wire title（UI draft 仍为 200，exact empty submit 仍为 `New Note`）；
  history/Undo 才可请求 nullable register target；
- NTL2 history 以 flags 表示 before/after 是否存在，decoder 继续接受旧 NTL1（旧记录两值必为 string）；
- runtime action、PersistentHistory、Undo/Redo validation 都保留 `string | null`，比较 UI 时只比较
  `null -> ""` 投影，发出 operation 时恢复真实 null。

## 5. Harmony 与原版的明确边界

本阶段修复的是 title register 的 wire、LWW、数据库、projection、出站和 durable history 一致性；没有
声称 Android Room/Notability 多设备真实同步、设备 UI 手感或完整 NOTE_BUNDLE round-trip 已由静态构建证明。
`note_meta.title` 为空只表示当前有效投影为空，不能据此推断 register row 缺席；需要审计/迁移/调试时应直接读取
`original_note_title_winner`。
