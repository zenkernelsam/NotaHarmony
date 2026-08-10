# ADR-0028：原版 CREATE_BLOCK IMAGE 数据合同

- 状态：Accepted（解码边界；应用仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0018、ADR-0020

## 原版证据

原版 1.0.3 `rl2` 的 CREATE_BLOCK fields 10/11/12/16/17 分别是 `dp5 ImageAsset`、inline `bmb Rect`、
web URL、水平翻转和垂直翻转。`hp5` 构造 IMAGE block 时强制取得 `dp5`，并保留 crop register、caption rich text、
两个 flip register 和 web URL；MIME 为 `image/gif` 时选择单独的 GIF view type。

`dp5` 要求 field 0 `wa0 metadata` table 和 field 1 inline `qed size`。`wa0` 要求 field 0 inline `ua0 AssetHash`、
非空 fileName、非空 mimeType，以及按 uint32 解释后大于零的 fileSize。`ua0` 是连续 8 个 uint64，共 64 bytes；
`qed`/`bmb` 复用原版 `ddg.i/ddg.h`，要求 float 有限、size 非负，crop origin 只要求有限。

`rl2.a()` 还明确拒绝 IMAGE 缺 asset、非 IMAGE 携带 image/crop/url/flip、非 MATH 携带 math 字段，以及非 TEXT
携带 paper。原版静态代码仍没有给出 `corner=ROUND` 的可证明像素半径，本阶段继续不猜常量。

## 决策

`OriginalCreateBlockPayload` 新增结构化 `image`、`cropRect` 和 `webUrl`。AssetHash 的 8 个 word 均保存为精确无符号
十进制字符串，禁止转成 JavaScript number；fileSize 保留完整 uint32，intrinsic size、crop、URL 和双向 flip 全量保留。

通用 `OriginalFlatBufferTableReader.readUtf8String()` 同时执行长度预算、FlatBuffer 末尾 NUL、UTF-8 decode/encode byte
roundtrip 三重检查，拒绝平台 decoder 的静默 replacement。文件名预算为 64 KiB、MIME 为 4 KiB、web URL 为 1 MiB；
inline uint64 helper 复用既有十进制算法。

type-specific 字段先于笼统 unsupported 判定，因而 TEXT/MATH 携带 IMAGE 字段、IMAGE 携带 MATH/paper 都返回具体原因。
合法 IMAGE 解码后仍返回 `CREATE_BLOCK_IMAGE_UNSUPPORTED`，且在读取页面或写数据库之前退出。

## 为什么尚不进入 APPLIED

当前 `PageElementKind`、`ImageElement`、`StrokePersistence` 和 `NoteCanvasView` 尚未共同覆盖原版 asset metadata、异步图片
所有权、crop/flip/transform/corner、GIF、层序、Undo、缩略图、导入导出和页面保存。现在写入半成品 IMAGE，编辑器下一次
全量保存可能把它删除；因此“解码合同已闭环”不能冒充“IMAGE 编辑生命周期已闭环”。

后续只有在统一元素 pass-through、资产 hash 映射、bitmap 生命周期和 renderer 同事务/同页面 replay 全部完成后，才能将
IMAGE 从 DEFERRED 改为 APPLIED。

## 验证

- `d02-create-image-block.mjs`：8 个 uint64（含超安全整数和 uint64 max）、中文 UTF-8、uint32 max fileSize、intrinsic
  size、crop、URL、flip，以及缺 asset、空 MIME、零 fileSize、NaN size/crop、坏 UTF-8、超预算、截断 hash 和坏终止符等
  9 类损坏输入。
- `SyncedOperationInbox.test.ets`：生产 decoder 字段断言，并以空 store 调用真实 applier，证明合法 IMAGE 在任何数据库访问前
  返回 `CREATE_BLOCK_IMAGE_UNSUPPORTED`。
- 全量 37 个 Node/SQLite replay 通过；`note@ohosTest` 与 `note@default` HAP 均完成构建。设备 Hypium 未执行。
