# Phase 269 修复总结：原版变宽 Ink 单调 Hermite 宽度曲线

## 基线与目标

- 基线提交：`2e8e796 fix(editor): preserve committed persistence state`。
- 正式且唯一修改工程：`C:\HarmonyProject\NotaHarmony`；Desktop `Notability` 仅只读原版 1.0.3 与逆向证据。
- Phase 264～266 已核验完整位于 `c1be5f0`：tree `b1a9dd87cde5871fe6f9f0fce58b03418a7e5e08`、
  3 commits、73 files，Phase 266 Replay 48/48。
- 目标：继续重放 M2-A-09，修复拟合 cubic 内仍对 `widthFactor` 做线性插值的真实缺口，恢复原版
  attributed path 的单调 Hermite/PCHIP 宽度 profile 与自适应属性组件切分。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 原版依据

原版 1.0.3 `z8a/jqi/fa2/ed0` 明确给出完整静态链：

- 多组件且宽度变化时，组件端点弦长至少钳制为 `1e-6`；
- 首尾导数使用首尾割线斜率；内部相邻斜率异号时归零，同号时用弦长加权调和导数；
- 以 cubic Hermite 插值组件宽度，并在 `0.25/0.5/0.75` 比较与线性宽度的偏差；
- 偏差乘 `1.2`，容差为 `max(start,end,0.05) * 0.005`，组件数按平方根公式钳制到 2～6；
- 以等参数区间切原曲线，在每个插入边界写入 Hermite stroke width，其他属性保持线性。

完整文件哈希、行号、公式和数值重放见
`docs/migration/evidence/original-variable-width-hermite-profile-jadx-2026-08-18.md`。

## 修复前真实缺陷

Phase 早期的 `ADR-0002` 已将原始折线替换为拟合 cubic 的自适应几何展平，也修复端帽、外圆弧 join、受限内交点与
实时/重载分叉；但 `flattenCubics()` 仍只取每个 cubic 两端的 `widthFactor`，递归二分时用算术中点线性插值。

这会导致：

- 相邻两段 `[1→3→2]` 的压力峰值在第一段被当作 `t=0.4 → 1.8`，原版应为 `1.992`；
- 第二段中点被当作 `2.5`，原版应为 `2.625`；
- 原版以斜率符号保护局部极值、以误差决定属性子组件数的逻辑完全缺失；
- 几何细分密度不能替代属性 profile，即使中心线足够平滑，轮廓半径变化仍不等价。

## 实际修改

### 原版宽度 profile

`WidthOutlineBuilder` 新增内部 `OriginalWidthProfile`：

- 由 cubic 端点和持久化 path point 建立组件宽度锚点；
- 按原版弦长、割线与单调导数公式构造 profile；
- 常量宽度和少于两个组件时不额外重建；损坏 cubic 继续回退有限中心线。

### 原版自适应属性细分

- 恢复三个探针、`1.2` 偏差安全系数、`0.5%` 相对容差与 2～6 clamp；
- 仅当 profile 相对线性宽度超过容差时，以等参数区间切源 cubic；
- 新增通用 De Casteljau `splitCubic(t)` 与 `sliceCubic(startT,endT)`；
- 每个子组件边界使用原版 Hermite 宽度，子组件内部再沿既有几何展平线性传递属性。

### 明确不扩大的结论

本阶段没有替换 `ADR-0002` 的最终 offset/join polygon。外圆弧、inside miter/bevel、cusp、自交与 Path 布尔轮廓
仍是 Harmony 已登记的可验证近似；只可声明“宽度属性曲线静态链闭环”，不能声明完整 bezierkit 轮廓算法等价，
M2-A-09/A-21 不整体关闭。

## Fixture 与 Replay

`WidthOutlineBuilder.test.ets` 新增：

- `[1,3,2]`、两段 10 单位直线 cubic，锁定第一段 `t=0.4 → 1.992` 与第二段 `t=0.5 → 2.625`；
- 全部生成轮廓半径不越过相邻宽度极值；
- 常量宽度不会仅因 cubic 列表存在而额外细分。

新增 `d02-original-variable-width-hermite-profile.mjs`，覆盖：

- 原版 `z8a/jqi/fa2/ed0` 源码门；
- 独立导数、Hermite、误差与细分数模型；
- Harmony 生产常量、公式、切 cubic 接线与 fallback；
- ArkTS fixture 内容及 suite 注册。

## 文档与补审

- 新增 ADR-0247 与原版 JADX evidence；
- 更正 `修复总纲.md` 中 A-21～A-24 仍停在“不得改/粗折线”的历史现场；
- 更正 `修复总纲2.md` 的 M2-A-09 与 69 文件覆盖矩阵：宽度 profile 已深审并恢复，但最终 offset 仍开放；
- 在总进展追加 Phase 269，保留 M2-R-13 选区缩放笔宽和设备像素验收。

## 验证结果

- 新专项 Replay：`TOTAL=25 FAILED=0`；
- 全量桌面 Replay：`REPLAY_FILES=254 FAILED=0`；
- `git diff --check` 通过；
- 首轮 `note@default` 终验捕获 ArkTS 不会从 `subdivisions` 反推 nullable profile 已排除的问题；实现改为显式
  null 分支提前 `continue`，不改变算法，并从 clean 起重新执行完整串行终验；
- 最终同一次 clean 链：clean `BUILD SUCCESSFUL in 2 s 148 ms`、`note@ohosTest`
  `BUILD SUCCESSFUL in 9 s 132 ms`、`note@default` `BUILD SUCCESSFUL in 44 s 994 ms`；
- 构建只有项目既有 ArkTS/deprecation 与未配置 signing warning，没有新增 error；
- `ohosTest` 只证明 fixture 已完成 ArkTS 编译/打包，不冒充设备执行 Hypium assertion。

## 当前结论与剩余边界

原版变宽 Ink 的 attributed-component 宽度曲线现已静态闭环：局部峰谷受单调导数保护，属性组件数由原版偏差公式决定，
插入边界与源 cubic 参数严格对应。仍需后续处理/验证：

- bezierkit offset/internal-arc、局部自交消解和最终 Path 布尔轮廓的完整等价；
- M2-R-13 在原版设备上对 0.5×/2× 选区缩放后的笔宽语义；
- 原版/Harmony 像素对照、压力峰值和急转弯观感、擦除命中、长笔画性能与内存；
- 真实保存重启、自有包和 Notability round-trip。

## Goal 纪律

T-042 APK 版本追踪继续严格留到整个 Goal 最后。本阶段不创建版本追踪目录、不执行新版 APK 全量 diff；最终必须另写
中文 Report，并把追踪文档/工具的用途、入口、阅读顺序和新版 APK decompile/diff 流程纳入 Wiki、技术/API 文档与
新手入门。
