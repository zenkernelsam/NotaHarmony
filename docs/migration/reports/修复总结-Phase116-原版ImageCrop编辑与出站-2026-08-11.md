# Phase 116 修复总结：原版 Image Crop 编辑与出站

## 原版证据与边修边审

- 直读原版 `dhb/ls/tp2/ns/t7`，确认 Crop 入口只接受单个 Image；进入后拖动只更新 `lsc/fi3` 草稿，
  不产生持久化。Close 清草稿退出，Reset 只恢复完整 intrinsic Image 范围，仍须 Confirm。
- `ns.s` 证明 Confirm 不是只写 crop field 12，而是同一条 type-23 `MODIFY_BLOCK` 同时写 page/origin
  fields 2/3、原 scale setter field 5、新 block size field 6 和 nullable crop setter field 12。
- 旋转图片的新原点使用旋转后的裁剪左上偏移；持久 crop 属于 intrinsic asset 坐标，UI 草稿属于当前
  block-local 坐标。Undo 回到初始无 crop 状态时，field 12 必须 present 且 value 缺席。
- 边修边审纠正了图标证据：原版 `t7` 实际依次使用 `feature_note__close/reset/checkmark`，本阶段直接复用
  三个反编译 vector path，而不是保留临时文字按钮。

## 已完成修复

- 新增 `OriginalImageCropGeometry`：建立/重置草稿、intrinsic domain clamp、旋转/非均匀正 scale 逆变换、
  Confirm 原点移动、float32 crop/size 与 world bounds 重算；输入 Image 始终 clone，不在拖动中污染模型。
- 新增旋转感知 `ImageCropOverlay`：四条真实旋转边、四角加四边共八个固定 32 vp 命中把手、稳定尺寸的
  Close → Reset → Confirm 工具栏、原版 vector 资产、主题 token 和中英文 accessibility 文本。
- Selection 菜单新增 Crop。仅单个未锁定 Image 且 intrinsic/crop/block/transform 可严格映射原版模型时显示；
  shear、reflection、perspective、非法 crop 及尺寸不一致的 legacy Image 保守隐藏入口，但继续正常显示和选择。
- `NoteCanvasView` 接入完整会话：crop mode 阻止普通绘画和选择拖动；screen delta 经 zoom 与 Image linear
  inverse 变为 local delta；Close 不写历史，Reset 只改草稿，Confirm 写单个 `TRANSFORM_ELEMENTS`、恢复选择、
  一次 persist 并通知 Undo/Redo；换页、离开页面和历史命令均取消未确认草稿。
- 新增 type-23 复合 encoder 与严格 snapshot classifier。普通保存及 grouped Undo/Redo 均复用原版 reducer、
  upload-immediate journal、单 revision batch、snapshot reconciliation 和 history companion；任一失败整体回滚。
- classifier 只接受单 Image 的精确 crop 投影，完整 persisted bytes 比较拒绝资源、URL、翻转、锁定、corner、
  wrap、caption 等夹带变化；支持首次 crop、existing crop、Reset full rect 及 Undo nullable clear。

## 测试与验证

- `OriginalModifyBlockPayloadEncoder.test` 新增 fields 2/3/5/6/12 round-trip、field-12 nullable clear presence
  和非法几何拒绝。
- `ImageBlockRendering.test` 新增旋转+非均匀 scale 原点移动、existing crop、完整 intrinsic Reset、输入不变，
  以及 locked/sheared/invalid/inconsistent 模型拒绝。
- `StrokePersistence.test` 新增正向 crop、反向 Undo clear、Reset full rect、multi-Image、scale 与无关字段拒绝。
- 新增 `d02-local-image-crop-outbound.mjs`，专项输出：
  `localImageCrop=original-draft-composite-rotated-origin-nullable-undo-ui-rollback`。
- 全量桌面 replay：`TOTAL=102 FAILED=0`；`git diff --check` 通过。
- 执行 `hvigor clean` 后严格串行构建 `note@ohosTest` 与 `note@default`，均为 `BUILD SUCCESSFUL`；仅有项目
  既有 ArkTS/deprecation warning 和未配置签名提示。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 仍待后续

- 真机集中验证旋转/缩放下八把手方向、最小尺寸手感、视口边缘工具栏、暗色图标对比、Close/Reset/Confirm、
  重启 Undo/Redo、既有 crop 和远端 replay；本阶段不虚报设备交互验收。
- 其余 entity outbound、格式闭环、私有认证 upload/ACK 与集中设备验收继续后续阶段，Goal 保持 active。
