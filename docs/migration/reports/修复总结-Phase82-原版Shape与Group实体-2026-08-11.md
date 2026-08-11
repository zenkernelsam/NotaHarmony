# Phase 82 修复总结：原版 Shape 与 Group 实体

日期：2026-08-11

基线：`9d7691b fix(sync): preserve original recording state`

范围：原版 payload type 18/19/20/21、type 24 Shape 分流、NOTE_BUNDLE、数据库 v56

## 原版证据

本阶段直读 `haa/rbb/ao2/le8/n5d/m5d/j0/l85/k85/cm2/vd8/a1j/fsi/v69`。确认：

- CREATE_SHAPE operation ID 就是 Shape ID；Shape 是页面元素，支持 LINE、POLYGON，以及当前原版
  1.0.3 中 NORMAL_SHAPE 的 ELLIPSE 实现。
- page+origin、rotation、scale、definition、tool、style、tapePattern、color、borderWidth、fillColor、
  zIndex、positionLocked、inkEffects、inkEffectsTinted 分别竞争 LWW，不能用单一 Shape winner。
- smartHighlight 与 force 仅属于 CREATE；MODIFY 的 nullable setter 与“字段不存在”语义不同。
- CREATE_GROUP operation ID 就是 Group ID。Group 不绘制，只保存非空 members 整表；MODIFY_GROUP
  对整表使用一个 LWW winner，删除 Group 不能删除其成员。
- `MODIFY_POSITIONS` 同样可以修改 Shape 的 page/origin、rotation、scale 与 zIndex。

## 实际修改

- 数据库升至 v56，新增 `original_shape_state`、`original_shape_modification`、
  `original_group_state`、`original_group_modification`；note 删除级联，迁移保持单事务。
- 新增 `OriginalShapeGroupOperation.ets`：
  - 严格解码 type 18 至 21，限制 target/member/point vector，拒绝 unknown field、非法 identity、
    非 finite 几何、空 Group 和不可物化 definition；uint64 不经 JavaScript number 丢精度；
  - LINE/POLYGON/ELLIPSE 物化为现有 `ShapeElement`，重算 bounds 并保留原版变换；
  - Shape CREATE/MODIFY、字段级 stale/site-tie LWW、exact retry/conflict、跨页移动、zIndex 排序；
  - 复用统一 visibility winner，覆盖 delete-before-create、hidden modify、undelete 与 deleted-page；
  - Group create/modify 使用完整成员列表 LWW，不触碰成员实体。
- standalone 与 NOTE_BUNDLE 均接入四类 payload；bundle preflight、应用与 Shape/Group 状态签名在同一
  事务边界内。生产统一路由从 27/31 达到 **31/31**。
- `OriginalModifyPositionsOperation` 新增 Shape target 分类，复用 Shape register reducer 与外部
  `OriginalPageMutationBatch`，保证混合 Ink/Block/Shape 一次提交页面 revision；不伪造 type-19 journal。
- ArkTS fixture 新增真实 Shape/Group FlatBuffer；22 个旧 replay 的当前 DB 版本守卫同步至 v56，并新增
  `d02-shape-group-state.mjs`。
- 静态复盘同时消除了 hidden Shape 路径对不存在 destination 的强制非空断言，并把 Shape winner JSON
  的 DDL 默认值从不可迭代对象 `{}` 纠正为与读取器一致的数组 `[]`。

## 验证

- 新 replay 覆盖 v55→v56 原子迁移/回滚、Shape retry/conflict、字段级 LWW/null、stale/site tie、
  跨页/zIndex、hidden modify/undelete、Group 整表 LWW、type 24 Shape 和 `routing=31/31`。
- 全量桌面 replay：`TOTAL=69 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均
  `BUILD SUCCESSFUL`；只有项目既有 deprecated/exception-handling warning。
- 未启动模拟器、真机或设备 Hypium，符合本轮约束。

## 边修边审新增项

- 原版 Shape 挂有 RichText CRDT，当前 Harmony `ShapeElement` 没有 Shape 内文字模型。这是新增明确审计项，
  后续必须复用已有字符 SeqId/visibility/style reducer，而不能把文本压成 Shape label 字符串。
- 当前 renderer 只消费几何、color、borderWidth 与 fillColor。tool/style/tapePattern/positionLocked/
  inkEffects 已无损保存但尚无完整视觉/交互 consumer。
- Group 已保存正确实体状态，但选择、组合移动、复制/export/outbound writer 尚未接入 Group consumer。

## 当前完成度与后续

31 类原版 payload 的统一生产入口已全部有明确处理路径，但这只是入站协议路由完成，不等于产品完成。
Goal 继续 active。下一批应优先处理 Shape RichText 与 Group consumer/自有包 CRDT 闭环，并继续完成录音、
资产迟到、私有同步服务、WebDAV、数据库真实升级及 30+ 设备/像素/交互验收场景。
