# 原版箭头识别解码证据（2026-09-28）

阶段：Phase 578。对象：原版形状识别链中第四个候选识别器 `y90(0).c()`（箭头）的完整解码，以及其唯一阻塞点 `ba0.b()` 箭头翼评分器。

## 1. 解码链（decompiled_1.0.3/sources/defpackage）

`e5d` 的候选识别器评估顺序已在此前阶段定为 `[cg7={y90-2 LINE, v6b}, y90-1 ELLIPSE, y90-3 POLYGON, y90-0 ARROW]`。本阶段完整解码 `y90.c()`（mode 0）：

1. `y90.c()` 对采样点序列计算局部转向角；角度 `>= 1.5707964f`（≈π/2，即 ≥90° 锐角）的连续区段各取最大角点作为候选拐角。
2. 在拐角处将笔画一分为二：前段（轴）送入 `cg7` 组合识别器，要求得到 `t06`（LINE）；后段（头部）送入 `br9`。
3. `br9.c()` 返回两个 `ba0` 翼识别器（`true`/`false` 两种镜像朝向），箭头两翼分别评分。
4. 合并置信度：`0.5·shaft + 0.5·head'`，其中 `head'` 在 `> 0.5` 时归一化为 `1.0`（原始代码 `min(head, 0.5)` 后再按分支处理，等价于头部过 0.5 即满分）。
5. 合法结果生成 `t06` 线段并调用 `t06.g(mask 31)` 强制写入 `s16.J` = **ARROW** 形状模式。

## 2. 唯一阻塞点：翼评分器不可反编译

- 1.0.3：`ba0.b()` 反编译失败，方法体仅为
  `throw new UnsupportedOperationException("Method not decompiled: defpackage.ba0.b():g5d")`。
- 1.0.1 对照（不同混淆表）：对应类为 `e90`，其 `b()` 同样未反编译。
- 仓库内无 smali/dex 文本导出（`Notability_1.0.3` 仅含 APK，`arm64_extracted` 为原生库），无替代字节码来源。

因此翼评分公式、阈值、翼端几何拟合目标均不可恢复。任何自行发明的箭头检测启发式都会背离原版语义，故本地箭头检测 **fail-closed**（ADR-0549）。

## 3. 已验证完整的三条腿（移植侧已齐备）

| 腿 | 原版证据 | Harmony 实现 | 状态 |
|---|---|---|---|
| 渲染 | `l96.W`：PathMeasure 测全长，箭长 `min(d1j.b(w), L)`，`d1j.b(w)=c(w)·46`；轴裁剪至 `L−箭长`；头为开口 V（基左→尖→基右），半展 `d1j.a(w)=c(w)·20` | `ShapeGeometry.ets` `lineRenderGeometry` / `originalShapeArrowScale`（逐字实现 `(f-2)/2+2`、`(f-4)/4+4`、`max(0,f)/7`） | 已对齐 |
| 入站操作解码 | 原始形状 op `arrowHead` 字段 | `OriginalShapeGroupOperation.ets`（`arrowHead===1→SINGLE`，越界报 "Line arrow is invalid"） | 已对齐 |
| 出站编码 | 同上字段 | `OriginalCreateShapePayloadEncoder.ets`（偏移 36 写 0/1） | 已对齐 |
| 部分擦除 | 头部属于形状轮廓 | `OriginalShapePartialEraser.ets` 将箭头 V UNION 入擦除外轮廓 | 已对齐 |
| 渲染器 | `l96.W` 返回 `ca0(主路径, 头路径)` | `ShapeStrokeGeometry.lineComponents` / `ShapeCanvasRenderer` | 已对齐 |

## 4. 缺失的两条腿（均不可恢复）

1. **本地检测**：`ba0.b()`/`e90.b()` 不可反编译 → 无法忠实移植。
2. **`.note` 解析**：plist 中箭头标志的原生键名无静态证据（现有键仅 `startPt`/`endPt`/`indices`/`kinds`/`options`），`NotabilitySessionParser` 维持 `ShapeArrowHead.NONE`（fixture 钉死）。

## 5. 结论

凡能进入 `arrowHead=SINGLE` 的路径（入站 CRDT op、未来解析扩展）渲染与擦除均已逐字对齐原版；本地检测因评分器不可反编译而 fail-closed，不发明阈值。回放：`d02-original-arrow-detection-failclosed.mjs`。
