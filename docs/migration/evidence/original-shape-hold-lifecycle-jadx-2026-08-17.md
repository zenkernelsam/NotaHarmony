# 原版形状长按吸附生命周期证据（JADX/调用图，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `y95.java`：`C753901B6B7DACD2925803116DD9534943C1BCE3B89D0AE4219C10CD714DFBDA`
- `tc5.java`：`69B9829C2C31AFDD875BF2957E73D174AA4E40894E19E7F7A162B1B18C54F5A8`
- `z95.java`：`96CB6379BD61152E8CB5F74D5F66DCCF5E2EADBB6BDCE76DA3F77F3D8F1267BE`
- `dzf.java`：`D32248D5544844F5B39DF2F2BA81E02208E991D15CC6D6AFBD2C4EF47FCAA530`
- `mw.java`：`E99FAF65AB257CCB775C767662E934912B8F8618E5021F3D0CE3A3F6D4C49FCF`
- `e5d.java`：`887EDAC44727BC716F8B680C1A7991FF046E9D0DBCBFFD5E4AD9B3F4C96485A2`
- `y90.java`：`DFF6F14200AA35050528827FC320ABD053CC2BDC5839619ABD40D00EFF193FD2`
- `a5g.java`：`D6F3539A8F05A1EB13A7C23106375D6B069285AC8EB41622EEA6514F59D14531`
- `zhh.java`：`D95C5457485694EA4BB30E4A4505B4486FFA834E11FFA35E837E3DC546F29453`
- `s16.java`：`2F5BDA82103F083956AF4EAA93D5FB1CEA5D5C0C9F234E90F4358E5EBAB0BB84`
- `aih.java`：`066E70F901F892250E83712D6BEAC6A2C375F2183594172326DA3DFDC3A6D2BD`
- `z4d.java`：`8A215346C02563F6B4464DBAB81BCFDD964F4732AAD7FC3F8B751A0809CDDE38`
- `t06.java`：`77FF1C84F1EB58BDEB41CF2984B49F9E3BE3AF699DEDA63AD6096263D79D6ABF`
- `i06.java`：`9EB777EEEF0419CC04DA2D63AD144777811F2253FE386424E9E9D6666D6CF775`
- `m06.java`：`E542E355FA8583765088475C18B9DFE759225F2764428E144133F2F027F29376`
- `b16.java`：`D9CC2D4EACE3DC89A7C12EFBD9E9737919F98E7FF3F4080F2DC81FACC4D20BC8`

Desktop 临时 JADX/callgraph 的完整清单、大小和 SHA-256 见
`docs/migration/evidence/desktop-codex-temporary-artifacts-2026-08-17.md`。原文件均仍保留，未清理。

## 1. Hold 延迟是精确 500ms

`y95.java:62-67` 在 coroutine 首次执行时直接调用：

```java
fag.B(500L, this)
```

延迟后才调用传入 callback。该值不是资源、远端配置或移植猜测，因此 Harmony 使用
`ORIGINAL_SHAPE_HOLD_DELAY_MS = 500`，并移除可由页面任意改写的 delay Prop。

## 2. 小抖动保留 job，跨 slop 才重启

`tc5.java:33-37` 在 Down 建立 `pauseDetectionLatestPoint`。`tc5.java:73-83` 对 Move 计算当前 MotionEvent 与该
anchor 的欧氏距离：

- toolType 2/3/4 使用 `handwritingSlop × 4`；
- 其他输入使用 touch slop；
- 仅当 `distance >= threshold` 才替换 anchor、取消 job 并把 job 置空；
- 小于阈值直接保留当前 anchor/job，不会因每个 Move 重新计满 500ms。

`dzf.java:9-10` 给 handwriting slop 默认值 2。`mw.java:24-29` 在 Android API 34 以上读取系统 handwriting
slop，低版本仍回退 2；`mw.java:38-39` 的 touch 分支读取 `ViewConfiguration.getScaledTouchSlop()`。
`z95.java:67-72` 在真正调度前取消旧 job，再 launch `new y95(...)`。

Harmony API 21 SDK 检索到 `SourceTool`，但没有公开 `touchSlop`、`handwritingSlop`、`ViewConfiguration` 或
`getScaledTouchSlop` 接口。因此 `HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP = 8` 只能是平台适配 fallback，
不能标成原版常量；pure helper 保留未来传入平台 baseSlop 的边界。

临时 `w95-simple.java:59-199` 进一步恢复了外层 MotionEvent flow：事件先交给 `tc5.a()`，只有 anchor 非空且
job 为空才调用 `z95.c()`；Up/Cancel/多指路径通过 `tc5.b()` 清理。其结论与正式 `tc5/z95/y95` source 一致。

## 3. 吸附成功后继续调整 Shape

`a5g.java:609-614` 取得识别结果后区分 LINE 与非 LINE。非 LINE 只有当前点距离 `zhh.a(...)` 几何 anchor
至少 5 时才接受；首个合格点只保存到稳定 adjustment origin。

### LINE

`a5g.java:622-655` 固定原 start，将 end 改为 `oldEnd + current - firstPoint`。当存在控制点时，代码把旧控制点
分解为相对旧主轴的 parallel/perpendicular 分量，再投影到新主轴；`a5g.java:643-647` 的两项公式同时保留
缩放与旋转，而不是只平移控制点。`t06.lineKind` 仍决定 `z90.SINGLE/NONE`，所以箭头头型不会因调整丢失。

### Ellipse

`a5g.java:656-672` 计算当前距离与首个调整距离之比，同时乘到 `m06.radiusX/radiusY`；`m06.rotation` 独立保留，
再重建 NORMAL_SHAPE 与 origin。因此必须统一缩放半径而不能重拟合成轴对齐圆。

### Polygon/Beziergon

`zhh.java:42-58` 以所有顶点平均值作为 anchor。`zhh.java:329-349` 用
`distance(anchor,current)/distance(anchor,first)` 非累积缩放每个点，再重建 POLYGON。Harmony 的多定义结果
没有单一原版对象 anchor，采用所有最终定义几何点的聚合 anchor，同时保持整批结果原子，不拆掉第二个元素。

## 4. confidence 与近圆规则

`e5d.java:158-164` 只在 `confidence > 0.2f` 时返回结果；等于 0.2 必须拒绝。Harmony 默认阈值因此从 0.5 改为
0.2，并将比较从 `<` 改为 `<=` 拒绝。

`y90.java:255-264` 的顺序为：

1. 构造带主轴 rotation 的 `m06`；
2. 先调用 `m06.a(points)` 得到评分；
3. 再求平均半径和短长轴比；
4. 当 ratio `>0.7`，或平均半径 `<30` 且 ratio `>0.5` 时，用平均半径重建 rotation=0 的圆；
5. 返回的 confidence 仍是归一化前拟合评分。

旧 Harmony 只在轴差小于 5% 时归零，既漏掉原版宽松近圆规则，也在归一化后重新评分。Phase 266 已按上述顺序
更正，同时保证大椭圆 ratio=0.6 不会因小椭圆例外被误圆化。

## 5. 内部八类不等于八种最终 ShapeDefinition

`s16.java:15-28` 的内部结果枚举确有：

`LINE / ARROW / SQUARE / RECTANGLE / TRIANGLE / POLYGON / ELLIPSE / BEZIERGON`

但 `z4d.java:18-21` 的最终定义只有：

`NONE / LINE / POLYGON / NORMAL_SHAPE`

`aih.java:45-79` 给出完整映射：

- `i06`（BEZIERGON）取控制几何点后构造 `u4d(POLYGON)`；
- `m06`（ELLIPSE）构造唯一 `t4d(NORMAL_SHAPE)`；
- `t06`（LINE/ARROW）构造 `s4d(LINE)`，ARROW 只把 arrow head 设为 `SINGLE`；
- `b16` 及其 Square/Rectangle/Triangle 子类构造 `u4d(POLYGON)`。

临时 callgraph 有 88,893 个 nodes、238,339 条 edges，并把 `k2f.k(...) -> aih.b(...)` 标为 resolved。
`.codex-tmp-phase266-k2f.java:426-480` 又恢复 `k2f` 接受 recognizer ordinal、调用 `aih.c/e/b/d` 并发布 `ge3`
的完整链。由此可确定 Harmony 不应为了内部名称扩展无 wire 证据的持久枚举；现有 LINE/POLYGON/ELLIPSE 与复合
结果模型足以承载最终联合。

## 6. Harmony 适配结论

- `ShapeHoldPauseTracker` 使用 screen-space anchor；sub-slop Move 不触发重新调度，达到阈值才重启。
- `ShapeHoldAdjustmentSession` 保存识别时 base geometry，所有更新非累积；LINE、Ellipse、Polygon 和复合结果分别
  按上述原版规则调整。
- Canvas 在成功吸附后隐藏原 stroke、显示 held Shapes，并让 Move/Up 调整它们；Cancel、翻页和生命周期退出共享 reset。
- timer callback 先归位 ID，避免已执行 handle 被后续清理误当成仍挂起任务。
- confidence、近圆和最终判别联合有硬证据；主动箭头/圆弧/曲线分类器没有等价 MyScript 证据，继续显式开放。

## 验证边界

静态 Replay/fixture 可以证明常量、比较符、timer/anchor 接线、调整数学、metadata clone 和最终联合映射。仍需设备验证
真实 platform slop、500ms 手感、吸附动画/preview、Up/Cancel/翻页残影、保存重启与 Undo；还需可信 provider 或更强
算法证据补齐 arrow/arc/curved-arrow/Beziergon 主动分类，不能用 HAP 构建冒充运行态或 MyScript 等价完成。
