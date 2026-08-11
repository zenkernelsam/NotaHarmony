# Phase 137 修复总结：原版 Group Paste 保留 Math Block

## 原版对照与问题

- 原版 `baj/rl2` 用 type-22 `CREATE_BLOCK` 的 field 13/14 同时创建 Math 的 LaTeX 与 Color，并复用
  common block 的 page、origin、rotation、scale、size、caption、corner、wrap 与 positionLocked。
- Harmony 已能消费、保存和显示 Math 状态，但出站 encoder 只有 Text 分支；Group Paste 因而把 Image 与
  Math 一起拒绝，即使 Math 不需要 Image 的资产事务。

## 已完成修复

- 新增严格 Math CREATE_BLOCK encoder，保留 LaTeX、signed ARGB、旋转、非均匀缩放、位置、尺寸、corner、
  wrap、caption 与 lock；拒绝非法 Unicode、超限字符串、shear、perspective、退化矩阵和非法枚举。
- Group Paste preflight 把 Math 纳入叶计数、层序和 bottom-up Group 图验证；Image 继续独立拒绝。
- 单事务按页面层序分配 Math identity，用生产 decoder/reducer 在共享 revision batch 应用 type-22，写入
  upload-immediate journal，然后继续 CREATE_GROUP 与单条 NCP1 history；任一步失败整体 rollback。
- 边修边审发现 float32 wire 与高精度剪贴板预览可能分叉。事务现从实际 decoded payload 重建返回 Math，
  让 original state、snapshot、NCP1 与 UI 安装使用同一 canonical 几何。
- UI 成功后安装 Math 数组并恢复 Math/top Group 选择；异步切页保护和原版复合 Undo/Redo 继续复用
  Phase 134/135 的路径。
- 新增 ADR-0114、`d02-original-group-paste-math.mjs`，升级旧 transaction replay，并扩展 encoder 与 plan
  ArkTS fixtures。

## 验证与边界

- 专项 replay 输出为
  `originalGroupPasteMath=type22-latex-color-transform-lock-single-revision-group-ncp1-canonical-ui-rollback`；
  升级后的旧 Group Paste transaction/UI replay 通过，全量桌面 replay 为 `TOTAL=123 FAILED=0`，
  `git diff --check` 通过。
- 执行 `hvigorw clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为
  `BUILD SUCCESSFUL`，只有项目既有 warning。未启动模拟器、虚拟机、真机或 Hypium。
- Image 仍需资产引用和本地文件可用性事务；Styled/空 Text、Shape RichText 仍明确拒绝。Math 的公式像素
  renderer 仍受 ADR-0036 记录的引擎缺口限制，本阶段只恢复原版数据对象与 Paste 事务，不虚报渲染完成。
