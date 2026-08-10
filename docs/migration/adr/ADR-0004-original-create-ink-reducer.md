# ADR-0004：原版 CREATE_INK 压缩路径与元素层序 reducer

- 状态：Accepted（受证明子集）
- 日期：2026-08-10
- 关联：D-02、数据库 v26、ADR-0001、ADR-0003 追加式页面恢复日志

## 背景

远端 `CREATE_INK` 不能复用 Harmony 本地落笔流程：原版 op 已携带稳定实体身份、压缩中心路径、变换和独立 uint64
z-index；重新拟合路径、按当前数组尾部插入或写入本地 `operation_log` 都会改变原版页面模型。删除页也仍保留原版页面对象和
内容，因此晚到笔迹必须更新远端删除归档，而不是等页面恢复后猜测补写。

原版 1.0.3 的静态证据来自 `haa/dm2/v69/s06/q06/lv2/ldj/w8a/t8a/zsa/be5/y18/vnd/so5/qo5`：

- `haa.CREATE_INK=15`，每个 op 以外层 `(timestamp,site)` 创建一个 `s06`；
- `dm2.B()` 的显式 z-index 覆盖外层 client time，缺省则使用 `uq9.k()`；
- `vnd.compareTo()` 对非 Tape 实体按 unsigned z-index、unsigned op timestamp、unsigned site 排序；
- 路径头高 5 bit 是版本、低 3 bit 是坐标编码，随后是 big-endian uint16 元素数；BITS_16 使用 big-endian half，
  BITS_32 使用 little-endian float32；带属性元素追加 half width/force 与 altitude/azimuth 字节；
- `t8a` 的 0～7 分别是带/不带属性的 cubic、quadratic、line、move；`s06.G()/cq.H()` 用全部端点和控制点的凸包，
  再向四周扩张 `2 * baseWidth`，不是曲线真实极值或逐点最大宽度；
- origin/rotation/scale 的组合是 `translate * rotate * scale`，scale 只要求有限，允许零值与负值翻转；生成的 tool/style
  accessor 对越界枚举字节回落到首项。

## 决策

新增 `OriginalInkPathCodec` 与 `OriginalCreateInkOperationApplier`，只对可以无损映射到当前 `StrokeElementData` 的子集返回
APPLIED：Pen/Highlighter，单 component center path，VARIABLE/FIXED/DASH/DOTS，line/quadratic/cubic 的精确三次表示，
逐点 width/force/altitude/azimuth，RGBA、基础笔宽、origin/rotation/scale，以及完整 uint64 z-index。

BITS_16/BITS_32 坐标按原字节序解码，不重新拟合；line 和 quadratic 以解析等价公式转成 cubic。变换以 Harmony row-major
矩阵保存：

```text
[cos*sx, -sin*sy, originX,
 sin*sx,  cos*sy, originY,
 0,       0,      1]
```

数据库 v26 新增 `original_element_z_index`，以 canonical decimal TEXT 保存 uint64，不能经过 JavaScript `number`。主键是原版
元素 `(noteId,timestamp,site)`，并关联稳定页面 SeqId。应用前要求目标 live snapshot 或远端删除归档中的每个既有元素都已有原版
层序元数据；缺一项即返回 `CREATE_INK_ELEMENT_ORDER_DIVERGED`，不覆盖本地或未知层序。成功后按原版比较器重排 dense
`element_order`、写入完整 stroke payload、推进 content revision，并使对应笔迹搜索状态失效。

元素写入、z-index、重排、搜索失效、inbox APPLIED、synced count 与 server cursor 继续由 `processHead()` 的外层单事务提交。
远端 reducer 不写本地 `operation_log`，也不进入 Harmony Undo/Redo。

以下能力继续返回具体 DEFERRED 原因，不做有损降级：Tape/pattern、多 component 或过短路径、未知路径版本/坐标编码、
custom/fill path、fill color、style map、audio duration、nib 属性、ink effects，以及缺失原版层序的既有内容。Pencil 不伪装成 Pen，
因为 Harmony Pencil 没有 splats 会渲染为空；其后续确定性 splat 子集已由 ADR-0023 开放。`NOTE_BUNDLE` 内 CREATE_INK 尚未接入内容 replay；本 ADR 也不涵盖
`ADD_PATH_ELEMENTS`、`MODIFY_INK`、实体 delete/undelete 或 block/text reducer。

## 后果与验证

- standalone CREATE_INK 的受支持子集可在 live page 和已归档删除页上按原版身份、几何、变换与层序收敛。
- 原版控制点凸包和 `2 * baseWidth` padding 被有意保留；不以看似更精确的曲线极值改变选择/脏区候选语义。
- `d02-create-ink.mjs` 覆盖真实 dm2 布局、两种坐标编码、属性、原版 bounds、RGBA、uint64、v25→v26、live/archive、
  搜索失效、分歧门禁与故障回滚。
- clean 后 `note@ohosTest` 与 `note@default` 均已完成静态构建；尚未运行设备 Hypium 或像素级原版对照，因此 D-02 不关闭。
