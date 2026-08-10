# ADR-0036：原版 MATH block 独立模型、LWW 与非伪装显示边界

- 状态：Accepted（数据与同步语义；公式像素引擎仍 Deferred）
- 日期：2026-08-11
- 关联：D-02、ADR-0023、ADR-0033、ADR-0034

## 原版证据

原版 1.0.3 的 `cz0.MATH = 2`，`u08` 只接受 `rl2.B() == MATH`，并由一份 common `ry0` 与 latex、color
两份独立 `yc6` register 组成。`u08.R()` 在 latex register 无值时返回空串；`ue4.G()` 在 color 无值时使用
ARGB 黑色 `-16777216`。`t08.c()` 对 MODIFY_BLOCK 的 latex 与 color 分别施加 register 操作，因此两字段必须
独立执行 LWW，不能共用一个 winner。

`rl2` 对 CREATE_BLOCK MATH 同时缺少 latex/color 的错误文本为 `Must provide latex and color for a Math Block`；
非 MATH block 也不能携带这两个类型专属字段。MATH 仍复用 common block 的 page/origin、rotation、scale、size、
corner、textWrap、caption、position lock 与 z-index。

原版显示不是把 LaTeX 当普通文字画出。`GLMathNative` 暴露 `nativeInit/nativeMeasure/nativeDraw`；`s18` 先调用
native measure，`p18` 建立 ARGB_8888 Bitmap 后调用 native draw，失败会 recycle 并返回 null。`ue4` 对空 LaTeX
直接不生成 bitmap，`h18` cache key 包含 block id、latex、ARGB、rasterScale、width、height。初始化、测量或绘制失败
都不会用 raw LaTeX 冒充公式结果。

## 决策

新增独立 `ElementType.MATH`、`PageElementKind.MATH` 与 `MathElement`，不把公式压成 TEXT。MATH 进入统一页面层序、
live/archive snapshot、跨页移动、页面删除 checkpoint、持久历史、自有包导入导出、主画布和缩略图 pass-through。
其 bounds 始终由 common transform 作用于本地 block rectangle 后重算。

数据库升到 v45。CREATE baseline 保存 latex 与 signed ARGB color；MODIFY 分别保存 latex/color value、timestamp、site
与 present。winner 缺席时回落 CREATE，显式 clear latex 物化为空串，显式 clear color 在数据库保留 null winner value，
显示物化为原版默认黑色。两字段的 stale/no-op、同 timestamp site tie-break、live/archive、跨页和 common register
均沿用原版 operation identity 语义。

CREATE 类型门禁抽成可测试的 `unsupportedOriginalCreateBlockReason()`。边修边审发现旧 TEXT-only 兜底仍位于已支持
IMAGE/MATH 的分支之后，导致合法 IMAGE 和 MATH 也会被误报为 `...FIELDS_ON_TEXT`；本阶段删除该过期兜底，并保留
跨类型字段和 MATH 缺字段的零修改拒绝。

## 显示边界

Harmony 当前仓库没有可证明与 `GLMathNative` 等价的公式引擎。为避免把原始 LaTeX 文本伪装成公式，非空 MATH
目前只按 block transform 绘制细虚线边界；空 LaTeX 不绘制。该元素暂时只读，不进入选择和编辑生命周期。

这保留了数据、几何、颜色、层序、同步与往返语义，但不宣称公式像素渲染、测量、缓存或编辑器已经接近原版。
后续只有在引入并验证真正的 LaTeX 公式引擎后，才能替换占位 renderer；不能以普通 `fillText()` 作为过渡成功路径。

## 验证

- `MathBlockGeometry.test.ets`：独立类型、深 clone、transform bounds、空 LaTeX 与 signed ARGB。
- `PageElementOrder.test.ets`：MATH 混合层序与自有包 LaTeX/ARGB/order round-trip。
- `SyncedOperationInbox.test.ets`：真实 FlatBuffer CREATE/MODIFY MATH、set/clear 与合法类型门禁。
- `DatabaseHelper.test.ets`：DB v45、CREATE baseline 和双 winner 列。
- `d02-math-block.mjs`：v44→v45/回滚、缺字段零写、RGBA→ARGB、双 LWW、stale、clear、common transform、
  跨页/z-index、live/archive 和故障全回滚。
- 全量 Node/SQLite replay：`TOTAL=45 FAILED=0`。
- `hvigor clean` 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`；未启动设备或执行 Hypium。

## Deferred 边界

本阶段不关闭公式 native 等价引擎、像素测量/绘制/cache、MATH 选择/编辑、ROUND corner、caption、GIF、
Tape/effects、NOTE_BUNDLE 内容 replay、PDF background、私有认证 transport 或服务端 note/site 创建。
