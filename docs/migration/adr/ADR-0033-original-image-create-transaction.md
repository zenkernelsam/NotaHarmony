# ADR-0033：原版 IMAGE CREATE_BLOCK 页面与资产同事务应用

- 状态：Accepted（metadata-only CREATE；资产字节 transport 仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0030、ADR-0031、ADR-0032

## 原版证据

原版 1.0.3 `v69.java:1584-1604` 在 CREATE_BLOCK 路径先从 `rl2.m()` 取得 `dp5`，以 `cp5(dp5)` 把
ImageAsset 暴露给资产集合，再以同一 `rl2` 构造 `hp5` IMAGE block。`cp5.a()` 只返回 `dp5.j()` 的 `wa0`
metadata；`dp5` 也只有 required metadata 与 size。CREATE_BLOCK 因此声明资产身份、文件 metadata 和固有尺寸，
不携带图片二进制，移植侧不得伪造文件或把 PENDING 冒充 LOCAL。

## 决策

`OriginalCreateBlockOperationApplier` 对合法 standalone IMAGE 构造完整 `ImageElement`：8 个 uint64 word 原样深复制，
页面快照使用稳定冒号 key，资产表使用原版 `ba6.f0` 的 64-byte little-endian hex storage key；crop 从
`x/y/width/height` 转为 `left/top/right/bottom`，并保留 transform、block/intrinsic size、corner、textWrap、caption、
URL、双 flip 与 position lock。IMAGE 与 Stroke/Text/Shape 共用 `original_element_z_index` 排序，live 与 archived 页面
走同一物化语义。

数据库升到 v43，在 `original_block_state` 保存 CREATE-time IMAGE metadata，作为以后 IMAGE MODIFY 独立 LWW register
的可靠 fallback。新 schema 对 required metadata、双 flip 和 crop 成组性加约束；升级数据库由 applier 的严格 decoder 与
写入路径保证同一合同。

资产合并直接使用 inbox 已开启的 SQLite 事务，不调用会再开事务的 `AssetRepositoryImpl.saveAsset()`：

- 无记录时插入 PENDING、`local_path=NULL`，并登记当前 noteId。
- 已有同 metadata 记录时只去重合并 noteIds，保留 status/local_path，尤其不降低 LOCAL。
- storage hex 与旧冒号 key 同时存在时合并到 storage key；优先保留可用本地路径/状态，旧 key 删除后现有快照仍可凭 bits 解析。
- file size/MIME 冲突或两个不同本地路径冲突时返回具体 DEFERRED，且在页面写入前保持零修改。

资产引用、z-index、block state、页面 snapshot/重排、revision/index 失效，以及 inbox APPLIED/cursor/count 均由
`SyncedOperationInbox.processHead()` 的外层事务覆盖；任何一步抛错全部回滚。IMAGE 不删除仍有效的 TEXT search items。

## Deferred 边界

本阶段没有实现图片字节网络 transport、PENDING→LOCAL 主动缩略图通知、MODIFY_BLOCK IMAGE crop/flip registers、GIF、
caption UI 或 ROUND corner 像素裁剪。MATH、Tape/effects 与 NOTE_BUNDLE 内容 replay 也不由本阶段关闭。

## 验证

- `d02-create-image-block-apply.mjs`：v42→v43、新 PENDING、LOCAL 保留、双 key 合并、metadata/path 冲突、live/archive、
  四类层序、幂等、inbox/cursor 原子推进及 8 个故障点回滚。
- 全量 Node/SQLite replay：`TOTAL=42 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。
- 未启动模拟器/真机，未执行真实远端图片到达、重启恢复、像素或内存验收。
