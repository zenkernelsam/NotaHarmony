# Phase 119 修复总结：原版本地 CREATE_SHAPE 出站

## 原版证据与边修边审

- 直读原版 `a5g/ge3/u5j/laj/ao2`，确认 hold 识别 Shape 走 type-18 `CREATE_SHAPE`：page/origin、
  rotation、definition、tool/style、color、borderWidth 与 average force 进入 18-field payload；本调用
  不带 fill/显式 z-index，不开 smart-highlight，未锁定，effects=0 且 tinted 默认 true。
- `ao2` 明确拒绝 variable-width style；LINE、POLYGON、NORMAL_SHAPE 分别由原版定义表编码，当前 1.0.3
  NORMAL_SHAPE consumer 只支持 ELLIPSE。
- 当前 Harmony 虽复用了预留 Ink 的 `op:*` ID，却在 Stroke→Shape 转换时丢失 page/clientTime metadata，
  导致 persistence 只能写私有 mutation 并永久阻断原版 authoring。边修边审还发现 visibility classifier
  只认 Ink，新 Shape 即使创建成功也无法用原版 delete/undelete 完成 Undo/Redo。

## 已完成修复

- 单个识别结果现在继承预留 identity、clientTime、原版 page identity、tool/style 与有效 pressure 平均值；
  多 definition 结果绝不共享一个 identity，style 0 也不伪装为可出站 Shape，二者保留兼容路径。
- 新增 `OriginalCreateShapePayloadEncoder`：严格编码 type-18 LINE（含控制点/箭头）、闭合 POLYGON 与
  rotated ELLIPSE。Ellipse 将 center/radii/rotation 换算为原版 origin + rotation；拒绝非 identity 外部
  transform、非法 tool/style、fill、lock、rich text、开口/超限 polygon 与非 finite 几何。
- clientTime 继续作为省略 z-index 的 decoder 默认值；reservation 已证明它不小于原版页面最大 z-index，
  因而 reducer 排序与 Canvas append 一致，不额外猜测层序。
- `StrokePersistence` 通过现有 type-18 reducer 写 `original_shape_state`、原版 z-index、页面 snapshot 与
  upload-immediate journal；reconcile、search、Harmony history companion、revision 和失败回滚保持单事务。
- 新增 `ORIGINAL_CREATE_SHAPE` 透明 companion。Undo/Redo 的 visibility classifier 扩展到 Ink/Shape，且
  每个目标必须命中对应原版 state 行，避免本地 `op:*` 假目标污染 delete-before-create 状态；选区直接删除、
  整对象橡皮擦与 Undo/Redo 三个入口都保留 Ink/Shape-only 的 type-25 路径。
- Shape snapshot 同时保留 `originalStyle`；旧 snapshot 从 resolved state 补 tool/style。Phase 118 type-19
  预检同步要求两者与 state 完全一致，避免新增 metadata 导致颜色/宽度路径降级或错发。

## 测试与验证

- ArkTS fixture 覆盖 type-18 LINE/POLYGON/rotated ELLIPSE、tool/style、force、默认 z-index 和 style 0 拒绝；
  ShapeDetector fixture 覆盖单结果 metadata 传递与多结果/style-0 清除。
- 新增 `d02-local-create-shape.mjs`，专项输出为
  `localCreateShape=type18-line-polygon-rotated-ellipse-tool-style-force-reserved-identity-state-preflight-single-revision-history-undo-redo-rollback`。
- 全量桌面 replay 为 `TOTAL=105 FAILED=0`；`git diff --check` 通过。`hvigor clean` 后严格串行构建
  `note@ohosTest` 与 `note@default`，均为 `BUILD SUCCESSFUL`；只有既有 warning 和未配置签名提示。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 仍待后续

- 多 definition 识别需要显式 reservation pool 或原子 ID rewrite 契约，不能复用一个 CREATE identity；
  当前明确保留兼容 persistence，不虚报原版闭环。
- 其余 Shape registers、本地 Group authoring、完整原版包 CRDT、私有认证 upload/ACK 与设备验收继续后续阶段，
  Goal 保持 active。
