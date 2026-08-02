# T-AUDIT 完成报告（对照 reference/defpackage/ 源码）

> 工人: 编码助手 | 日期: 2026-08-02 | 状态: 待指挥官复核

## 审计说明

本次以 `reference/defpackage/*.java`（17 个反编译源文件）为唯一事实来源，逐方法对照审计。REVERSE_ANALYSIS.md 仅作辅助。第一梯队（4 个核心算法）逐方法对照；第二梯队（5 个文件）参数/映射核验。发现偏差直接修正（只改偏差行），无法确认的标注 ❓。

## 逐个审计结论

| # | 文件 | 对照源码 | 结论 | 要点 |
|---|------|----------|------|------|
| 1 | ForceSmoother.ets | ms1.java + dr4.java | ✅ 一致 + ❓ 一项 | dr4 构造调用 `new dr4(0.15f, 8ms, true)` 逐位一致；`maxForceChangePerPoint` 字段名证实"每点变化限制"语义正确；8ms 窗口的参与方式在执行类 vy5/d30/yc4（不在 17 文件）→ ❓ |
| 2 | CubicFitter.ets | sqh.java + gp2.java | ⚠️ 偏差已修正（7 处） | 见修正清单 1-7；gp2.c(t)/j(t) 公式已核验 |
| 3 | WidthOutlineBuilder.ets | w4a.java + y5a.java + hz5.java | ⚠️ 结构差异已确认 + ❓ | 原版 w4a.b() = Hermite 宽度插值细分（容差 max(w)*0.005，细分 clamp(ceil(sqrt(dMax*1.2/tol)),2,6)）+ 局部极值分割 + ic0.I() 轮廓（ic0.java 缺失）；我们的法向量偏移实现无法逐行对齐；单点帽公式 `w*0.5*baseWidth` 一致；不改代码（对齐需 ic0 源码） |
| 4 | PencilSplatGenerator.ets | xaa.java + oz5.java + te6.java | ⚠️ 偏差已修正（7 处） | 见修正清单 8-14；散布/位置/LCG/弧长二分与 xaa.b() 逐行一致 |
| 5 | InkInputProviderImpl.ets | hda.java + cu5.java | ⚠️ 偏差已修正（1 处） | pressure clamp[0,1]/tilt[0,π/2]/orientation[0,2π)/无能力 -1 与 hda.v() 一致；predicted 时间戳改为事件级过滤（cu5）；toolType 源码为 5→3 归并（stylus/mouse 同组），x16 枚举缺失 → ❓ 保留三态映射 |
| 6 | Canvas2DStrokeRenderer.ets | pzf.java + uaa.java | ⚠️ 偏差已修正（1 处） | DASH [2w,1w]/DOTS [0.001w,2w]/荧光笔 107/round join 一致；DASH/DOTS 线帽修正为 BUTT（pzf this.i 画笔） |
| 7 | EraserEngine.ets | pzf.java（h76 相关） | ✅ 一致 + ❓ | PARTIAL maskPath（渲染器 destination-out 挖洞）/ WHOLE 不碰 maskPath / AABB 相交；pzf 无擦除逻辑（在缺失的 h76）→ 行为按任务卡/§5b，标注待 h76 |
| 8 | StrokeSession.ets | s78.java + jv5.java | ⚠️ 偏差已修正（1 处） | finishInput→g()/cancel() 语义一致；splat 生成器改为按笔刷宽度重建 + seed 用笔画起始时间戳（oz5.t/hud.f）；widthFactor=0.3+0.7p 为假设（原版 fc0.e()/xqh.c 数据源缺失）🟡 保留 |
| 9 | ShapeDetector.ets | b90.java | ✅ 一致 + ❓ 一项 | 直线 fC/跨度≤0.6 拒绝/最小长度 60/评分提升 max((1+score)*0.5, score)/椭圆首尾距<120/置信度 0.5 全部与 b90 一致；多边形顶点范围原版多分支（4~6 附近）无法简洁确认，保留 3~8 → ❓ |

## 修正清单（对照源码逐行）

### CubicFitter.ets（← sqh.java / gp2.java）

| # | 修正 | 源码位置 |
|---|------|----------|
| 1 | **两点特例**：4 控制点全同（笔点退化段） | sqh.g L611-613（i12==2） |
| 2 | **三点特例**：中点二阶外插 `dB3=2*P1-(P2+P0)*0.5`，`p1=P0/3+dB3*2/3`，端点取收集数组首末点（含上下文） | sqh.g L624-633（i12==3） |
| 3 | **病态判据**：`abs(det)<1e-9` → `det <= 1e-9*s11*s22`（相对阈值，无 abs） | sqh.g L668 |
| 4 | **非有限判据**：isFinite → `abs(x) > Double.MAX_VALUE` 才回退（NaN 不回退） | sqh.g L675 |
| 5 | **误差检查**：50 步最近点搜索 → 按 `t=(i-start)/(end-start)` 直接求曲线点欧氏距离（1e-12 下界过滤） | sqh.h L699-706 |
| 6 | **分段策略**：递归对半拆 → ≤200 点直接接受（sqh.h 语义）+ >200 点二分找最长可接受终点（wy5 语义）+ 段未覆盖末尾且前后各 ≥4 点拆半重拟合 | sqh.h L692 / sqh.f L520-529 / sqh.f L541-549 |
| 7 | **段间连续性修正**：`p1 = p0 + 前段 j(1.0) 切向投影`（新增 applyContinuity） | sqh.f L306-335 |

### PencilSplatGenerator.ets（← xaa.java / oz5.java / te6.java）

| # | 修正 | 源码位置 |
|---|------|----------|
| 8 | tiltNormalize：-0.94248 → **-0.9424777960769379**（完整 double） | xaa.d L46 |
| 9 | angleNorm 分母：0.45332 → **0.45331853071795863** | xaa.b L198 |
| 10 | scale：`ellipseS*spacing*sizeFactor` → **`ellipseS*spacing*(sizeFactor*0.5+0.5)`** | xaa.b L197/L199/L236（d10*d11） |
| 11 | opacity：splatCount==1 时因子为 **1.0**（非 (1-√u1)） | xaa.b L226/L230 |
| 12 | 步进：固定 spacing → **预步进 spacing*0.25**（te6.q 传 ow5Var=null 分支）+ **动态步长 spacing*0.25*(sizeFactor*0.5+0.5)** | xaa.b L174/L259 |
| 13 | spacing 语义：默认 2.0 → **= 笔刷宽度**（StrokeSession 按 renderSpec.brushWidth 重建生成器） | oz5.t L242（dC0=ry5Var.c0()） |
| 14 | 有限守卫：超 **Float.MAX_VALUE（3.4028235e38）** 跳过该 splat；seed 改用笔画起始时间戳（原版 hud.f()） | xaa.b L235 |

### 其他

| # | 文件 | 修正 | 源码位置 |
|---|------|------|----------|
| 15 | InkInputProviderImpl.ets | predicted 时间戳 0：点级过滤 → **事件级忽略整个事件** | cu5 L113 |
| 16 | Canvas2DStrokeRenderer.ets | DASH/DOTS 线帽 'round' → **'butt'**（实线保持 round） | pzf L44-53（this.i 画笔 BUTT） |
| 17 | StrokeSession.ets | splat 生成器按笔刷宽度重建 + seed=startTime；splatSeed 字段保留兼容 | oz5.t / hud.f |

## 遗留假设清单（❓ 真正无法确认的项）

| 项 | 位置 | 假设内容 |
|----|------|----------|
| 1 | ForceSmoother | 8ms 窗口的参与方式（执行类 vy5/d30/yc4 缺失；dr4 仅确认参数） |
| 2 | WidthOutlineBuilder | ic0.I() 轮廓几何（法向量/帽/尖角）在 ic0.java（缺失），w4a.b 的 Hermite 细分与极值分割未移植（结构差异，功能等价性待真机视觉回归） |
| 3 | InkInputProviderImpl | x16 枚举语义缺失：hda.v() 把 STYLUS 与 MOUSE 归同一组，与我们的三态映射不同，待 x16 确认 |
| 4 | StrokeSession | widthFactor=0.3+0.7p（fc0.e()/xqh.c 数据源缺失，🟡 §35 未闭环） |
| 5 | PencilSplatGenerator | interpolateAttributes 的 pressure 由 widthFactor 反推 (w-0.3)/0.7（原版用 fc0 实时数据）；弧长行走 vs 原版欧氏距离判据（小步长等价） |
| 6 | ShapeDetector | 多边形顶点范围（b90 多分支 [4,6] 附近，MVP 保留 3~8）；椭圆归一化圆判据（f3<30 && ratio>0.5 等）未移植 |
| 7 | EraserEngine | h76 擦除细节（bounds 相交为 MVP 近似） |
| 8 | CubicFitter | dd4.d() 精确函数缺失（Math.log 近似保留）；w76.l0 推断为欧氏距离 sqrt |

## 验收结果

| 验收项 | 结果 |
|--------|------|
| 9 个文件全部有审计结论（✅ / ⚠️ 已修正 / ❓） | ✅ |
| 修正后 check_ets_files 零错误 | ✅（9 文件 no diagnostics） |
| build_project 编译通过 | ✅（BUILD SUCCESSFUL，仅既有平台层 deprecation 警告） |
| 不修改 Phase 1 契约接口签名 | ✅（仅私有方法/内部逻辑变更；StrokeSessionConfig.splatSeed 保留兼容） |
| 不修改平台层代码 | ✅（仅 algorithm/adaptation/rendering 逻辑层） |
| 完成报告含逐项结论 | ✅ |
