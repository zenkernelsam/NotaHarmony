# ADR-0011：原版 Ink 辅助路径、填充色与独立 LWW

- 状态：Accepted（custom/fill path 与 fill color 受证明子集）
- 日期：2026-08-10
- 关联：D-02、数据库 v33、ADR-0004、ADR-0006、ADR-0010

## 背景

原版 `wd8` 的 MODIFY_INK fields 9/10 是 encoded custom/fill path vector，field 11 是可空 `SetColor`。
`q06.c():606-620` 将三者分别送入 `customPathRegister`、`fillPathRegister` 和 `fillColorRegister`；字段缺席不修改，
vector 出现但长度为零或 `SetColor(value=nil)` 表示 winning clear。CREATE 侧 `dm2` fields 10/11/12 提供三个 register
没有 winner 时的初值。

`i16.java:151-175` 把 `s06.U()/W()/V()` 分别转换为 `nwd` 的 custom path、fill path 和 fill color。
`e16.java:153-198,200-252` 证明它们不是只用于持久化：fill 先画 `fillPath`，缺席时回退 center path；半透明 fill
通过 custom path 或由中心线和宽度生成的描边轮廓执行 clip-out，避免内部填充加深主笔迹。custom path 对普通定宽/变宽 Ink
直接填充，对 DASH/DOTS 则裁剪中心线描边。Android `Path` 的 move/line/quadratic/cubic 和多个 move component 必须保留，
不能压成中心线点列，也不能借用仅属于像素擦除的 `maskPath`。

## 决策

1. `StrokeElementData` 增加独立 `customPath`、`fillPath` 和 nullable `fillColor`；路径保存 verb 与每个 verb 的控制点。
2. `OriginalInkPathCodec` 对辅助路径保留 move/line/quadratic/cubic、多 component 和控制点凸包；空 vector 归一化为 clear。
3. CREATE_INK 解码 fields 10/11/12，建立无 winner fallback，并把辅助路径 hull 纳入变换后 bounds。
4. MODIFY_INK 开放 fields 9/10/11，各自按 `(timestamp,site)` LWW；winner-presence 与 nullable value 分列，显式 clear
   不能退化为“没有 winner”。旧 v32 行首次 winning 修改从保留的 CREATE_INK envelope 恢复 fallback，并在写入前核对当前 Stroke。
5. 数据库升至 v33，为三组 register 保存 CREATE fallback、winning value、winner identity 和 presence；多 Ink 仍先全量规划，
   与 snapshot、页面 revision、搜索失效及 inbox cursor 共用外层事务。
6. `StrokeCanvasPainter` 固定采用 fill、主 Ink/custom path、像素 mask 的顺序；包解析、剪贴板、Undo、选择变换和擦除复制路径时
   都保留这些字段。
7. field 12 style map、nib、Pencil/Tape 和 effects 继续 DEFERRED；不以本阶段的辅助路径支持替代其实际语义。

## 后果与验证

- `d02-modify-ink-auxiliary-paths.mjs` 覆盖真实 fields 9/10/11、nullable clear、v32→v33、legacy CREATE fallback、
  三 register 独立 winner、乱序拒绝、多 Ink 原子性、回滚、渲染源码契约和无本地日志。
- `SyncedOperationInbox.test.ets` 增加 move/line/quadratic/cubic、多 component、CREATE fields 10/11/12、MODIFY value/clear
  与 style-map 继续 unsupported 的 FlatBuffer fixture。
- 全部 24 个 D-02 桌面 replay 通过；clean 后 `note@ohosTest` 与 `note@default` assembleHap 均 BUILD SUCCESSFUL。
- Harmony Canvas 的 `clip('evenodd')` 仅完成 SDK/ArkTS 编译门，半透明 fill 的像素结果仍需设备对照；不据此关闭完整
  MODIFY_INK 或 D-02。
