# Phase 138 修复总结：原版 Group Paste 保留 Image Block 与资产引用

## 原版对照与问题

- 原版 `baj/rl2/iuh/k1j` 通过 type-22 CREATE_BLOCK field 10/11/12/16/17/20 保存 ImageAsset、crop、
  URL、双 flip 与 lock；ImageAsset 内再保存 8 个 uint64 SHA-512 word、文件 metadata 与固有尺寸。
- 原版 CREATE_BLOCK 只声明资产，不携带图片字节。Harmony 入站 reducer、资产到达链路和 loader 已完整消费，
  但出站 encoder 和 Group Paste 仍拒绝 Image，导致含图片的原版 Group 无法精确保真粘贴。

## 已完成修复

- 新增严格 Image CREATE_BLOCK encoder，保留 hash words、文件名/MIME/uint32 size、固有与块尺寸、旋转/
  非均匀缩放、crop、URL、caption、corner、wrap、双 flip 与 lock；拒绝 hash key 分叉、非法 UTF-8/
  长度、非法 crop/枚举、退化矩阵、shear 和 perspective。
- Group Paste preflight 把 Image 纳入叶计数、精确层序和 bottom-up Group 图；完整 payload 在首次写入前
  编码验证。事务按页面顺序分配 Image identity，用生产 decoder/reducer 加入共享 revision batch，并写
  upload-immediate journal，随后继续 CREATE_GROUP 与单条 NCP1。
- 复用 reducer 的同事务资产合并：跨笔记粘贴去重加入目标 noteId，已有 LOCAL/path 不降级；canonical/
  legacy key 归并；无记录按原版 metadata-only 语义建立 PENDING；metadata/path 冲突使整个 Paste 回滚。
- 从实际 decoded wire payload 重建返回 Image，使 float32 transform、固有/块尺寸与 crop 在 original state、
  snapshot、NCP1 和 UI 之间一致。UI 安装并选中新 Image 后刷新 loader generation，本地资产立即重载，
  PENDING 资产继续通过既有到达通知自动刷新。
- 新增 ADR-0115、`d02-original-group-paste-image.mjs`，升级 transaction/Math/UI replay，并扩展 encoder 与
  Paste plan ArkTS fixtures。

## 验证与边界

- 专项 replay 输出为
  `originalGroupPasteImage=type22-sha512-metadata-crop-url-flips-lock-asset-reference-canonical-ui-rollback`；
  全量桌面 replay 为 `TOTAL=124 FAILED=0`，`git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、真机或 Hypium。
- Styled/空 Text 与 Shape RichText 仍是 Group Paste 明确门禁。原版私有认证下载 transport 仍按 ADR-0035
  保持 Deferred；本阶段没有伪造网络协议，而是正确保留 PENDING 引用并复用已实现的校验到达链路。
