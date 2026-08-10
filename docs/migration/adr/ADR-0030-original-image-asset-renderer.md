# ADR-0030：原版 IMAGE 资产映射与静态 renderer

- 状态：Accepted（静态主画布边界；动画与编辑仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0028、ADR-0029、M2-R-09、M2-F-03

## 原版证据

原版 1.0.3 `ba6.e0/f0` 将 `ua0 AssetHash` 的 8 个 uint64 各按 little-endian 写成 8 bytes，再把完整 64 bytes
编码为 128 位 hex。`zq6.h` 的本地文件、原版包的 `assets/` 条目和媒体路径都使用这个 storage hash；`s01.W`
的逐 word 十六进制是另一套缓存/传输身份，不能替代本地文件名。

`b40.D` 禁用 hardware bitmap，并在最大边超过 3000 时等比缩到 3000。`b40.E`/`kd` 的静态绘制先把 intrinsic
crop 换算为实际 bitmap 像素，再应用 block/page transform、按 crop 可见尺寸缩放并 clip，最后对完整 bitmap 应用
水平/垂直 flip 后绘制。原版 GIF 使用独立 view type，不能把静态首帧当作动画支持。

## 决策

`originalAssetStorageHash()` 以十进制长除法处理 canonical uint64 字符串，精确复现 `ba6.e0/f0`，不经过 JavaScript
不安全整数。资产查找首先使用原版 storage hash，并兼容 ADR-0029 早期内部冒号 key；画布缓存和包内去重只使用 storage
hash，避免同一资产因兼容 key 不同而重复解码。

`ImageAssetLoader` 从 `note_asset.local_path` 解码静态图片，校验元素、数据库和实际文件长度；最大边按原版限制为 3000。
加载结果显式区分 `MISSING/PENDING/READY/FAILED/ANIMATED_UNSUPPORTED`。页面 generation、资产 generation 和 pageId
共同阻止快速切页后的迟到结果串页；页面替换、失败态和组件退出均关闭 `ImageBitmap`，释放 `PixelMap/ImageSource` 与文件句柄。

`ImageCanvasRenderer` 按原版 crop 像素换算、transform、可见尺寸缩放、clip、全图 flip、draw 的顺序进入统一 z-order。
无效或空 crop 不绘制。ROUND corner 没有可静态证明的原版像素半径，继续不猜常量。

边修发现自有 `.note` v1 此前只导出 IMAGE JSON，不导出二进制，导入却会返回成功。现在导出唯一的
`assets/<ba6.f0 hash>`；缺 metadata、本地文件或长度不符会使导出失败，禁止生成不可恢复包。导入先盘点全部 IMAGE：
旧包缺资产或长度不符返回 PARTIAL；同一 storage hash 的 fileSize/MIME 声明冲突视为包损坏。二进制写入临时文件、完整
写入、`fsync` 后 rename，再登记 `note_asset`；登记失败清理本次新文件。已有文件必须逐字节一致才复用，已恢复的
PENDING/FAILED metadata 转为 LOCAL，并合并 note 引用。进程在 rename 与数据库登记之间退出最多留下可复用的同名孤儿文件，
后续同 hash 导入会逐字节核对并补登记，不会覆盖不同内容。

## Deferred 边界

本阶段不把 CREATE_BLOCK IMAGE 改为 APPLIED。远端 op 仍需要资产与页面状态同事务 fixture；IMAGE 的选择、擦除、变换、
caption、缩略图、GIF 动画和 ROUND corner 像素裁剪尚未闭环。网络下载/远端 asset transport 也未建立。

## 验证

- `d02-image-asset-renderer.mjs`：little-endian storage hash、crop/downsample、clip-before-flip、3000 边长、GIF deferred、
  bitmap 生命周期、包资产、原子文件、内容/metadata 冲突、缺失 PARTIAL 和页面 generation 源码门。
- `ImageBlockRendering.test.ets`：storage hash/package entry、兼容 lookup key、共享资产 metadata 一致性、crop 像素与空 crop。
- 全量 Node/SQLite replay：`TOTAL=39 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。
- 未启动模拟器/真机，未执行设备 Hypium 或 crop/flip 像素对照。
