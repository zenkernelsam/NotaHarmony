# ADR-0035：原版图片资产 SHA-512 接收与主动刷新

- 状态：Accepted（transport-independent 字节接收；私有认证 transport 仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0030、ADR-0033、ADR-0034

## 原版证据

原版 1.0.3 `re0.java` 把输入流写入 `assets/pending/pending_asset_*.tmp`，输出端由
`DigestOutputStream(..., MessageDigest.getInstance("SHA-512"))` 包装；只有完整写入后才返回临时文件与计算出的
`ua0` AssetHash，失败会删除临时文件。`ge4.java` 的本地导入路径也明确以 `MessageDigest.getInstance("SHA-512")`
逐块计算同一资产身份。

`vs8.java` 取得临时文件和 digest 后，以 `zq6.h(context, ua0)` 定位最终文件，替换/移动成功后才写 NoteAsset
记录与实际文件长度。`zq6.g/h` 证明最终目录是应用私有 `assets/final`，文件名是 AssetHash 64 字节的 canonical
hex。CREATE_BLOCK IMAGE 只登记 metadata/PENDING，资产字节必须沿独立链路到达。

原版 worker 还区分可重试网络故障与永久 4xx，但反编译代码没有给出可以安全移植的私有 endpoint/token 合同；本阶段
因此只建立收到完整字节后的确定性边界，不虚构网络协议。

## 决策

新增 `sha512Hex()`，并用标准 `SHA-512("abc")` 固定向量锁定 digest 及 FlatBuffer 八个 uint64 word 到 storage
hex 的 little-endian 字节顺序。图片导入和远端到达都必须先验证长度、MIME metadata 与完整 SHA-512；hash 不符时
不得创建文件或修改数据库。

`receiveOriginalImageAsset()` 只接受已由 CREATE_BLOCK IMAGE 登记的资产：

- 在 `assetMutationMutex` 内读取 storage/legacy key，拒绝未登记或 metadata 冲突；同 hash 并发接收与资产/笔记删除串行。
- PENDING/FAILED 写入 `assets/pending/pending_asset_*.tmp`，循环完整写入并 `fsync`，再原子 rename 到
  `assets/final/<sha512>`；数据库提交后才对外可见为 LOCAL。
- 已有相同 LOCAL/UPLOADED/DOWNLOADED 文件为幂等成功，保留原 status 与合法路径；内容、可用路径或双 key 冲突不覆盖。
- storage/legacy 双 key 在同一事务归并，noteIds 保持原顺序去重；数据库失败回滚，并尽最大努力删除本次新建 final 文件。
- 导入包复用同一写入核心，因而也不能再用只匹配长度但 hash 错误的图片冒充合法原版资产。

数据库提交后，`AssetAvailabilityHub` 按 storage hash/noteIds 发布 generation。当前画布只在当前页确实引用该 hash 时
使迟到 loader 失效、释放旧 PENDING/FAILED entry 并重载；资料库把 note asset generation 纳入缩略图 cache identity，
丢弃旧 generation worker 后调用既有受控刷新。两处均在组件离开时 unsubscribe，避免持有失活 UI。

## Deferred 边界

本阶段没有实现或宣称原版私有服务器 endpoint、token/auth、下载调度和 HTTP retry worker 已接通。GIF 动画仍明确
unsupported；caption rich text/UI、ROUND corner 像素半径、MATH、Tape/effects、NOTE_BUNDLE 内容 replay、PDF
background 与服务端 note/site 创建也不由本阶段关闭。

## 验证

- `AssetArrival.test.ets`：标准 SHA-512 向量、uint64 字节序、事件 generation、去重与 unsubscribe。
- `ThumbnailRenderPolicy.test.ets`：资产 generation 改变缩略图 cache identity。
- `d02-image-asset-arrival.mjs`：真实 SHA-512、PENDING→LOCAL、双 note、长度/hash/MIME 零修改、LOCAL 幂等/冲突、
  外部合法路径保留、未登记拒绝、rename/数据库故障补偿、通知与生命周期源码门。
- 全量 Node/SQLite replay：`TOTAL=44 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`；未启动设备或执行 Hypium。
