# ADR-0244：原版形状长按吸附生命周期

## 状态

Accepted - Phase 266（2026-08-17）

## 背景

M2-R-12 早期阶段已让 Harmony 能保存 LINE/POLYGON/ELLIPSE 和复合识别结果，但 hold 生命周期仍是移植方近似：

- 500ms 被标成暂定可注入值，任何 Move 都重启计时；
- 吸附成功后继续移动会撤回 Shape、恢复原笔迹并重新识别；
- 没有复刻原版吸附后调整终点/尺度的交互；
- confidence 默认 0.5，近圆规则也比原版严格；
- 文档混淆原版内部八类 recognizer result 与最终 ShapeDefinition 联合。

直读 `y95/tc5/z95/dzf/mw/e5d/y90/a5g/zhh/s16/aih/z4d/t06/i06/m06/b16` 后，以上规则均能由
原版 1.0.3 静态证据确定。完整哈希和行号见
`docs/migration/evidence/original-shape-hold-lifecycle-jadx-2026-08-17.md`。

## 决策

### Pause detection

- hold 延迟固定为原版 `500ms`；移除会让调用方伪造不同交互的 `shapeHoldDelayMs` Prop。
- Down 建立 screen-space pause anchor 并启动 job。Move 小于 slop 时保留原 anchor 和当前 job；距离达到阈值
  才移动 anchor、取消旧 job 并重启。
- Pen/Mouse 使用 handwriting slop ×4；touch 使用 touch slop。Harmony API 21 没有公开
  ViewConfiguration-style slop 查询，因此 2/8 只作为显式平台 fallback，helper 保留未来注入 baseSlop 的边界。
- timer 回调先把 Harmony timer ID 归位 `-1`，再检查 lifecycle、工具、stroke session 和识别结果。

### 吸附后调整

- 识别成功后隐藏活动原笔迹并保持 Shape preview，不再因后续 Move 恢复原笔迹或重启识别。
- 单个 LINE 固定 start，首个调整点成为稳定 origin；之后只移动 end，并以原 start/end 基底相似变换控制点，
  因而直线、quadratic、cubic 和 SINGLE arrow head 都保真。
- 非 LINE 先要求当前点距几何 anchor 至少 5px，再将首个合格点固定为缩放 origin；Ellipse 保留 rotation 并统一
  缩放两个半径，Polygon/多定义结果围绕聚合 anchor 非累积缩放。
- Up 的最终 changedTouch 仍进入 adjustment，然后原子提交完整 ShapeDefinition 集合。

### 取消与页面生命周期

- normal Up、Cancel、第二指接管、指针丢失、翻页、加载失败和 `aboutToDisappear()` 都通过共享 reset 清理 timer、
  pause anchor、adjustment session 与 preview。
- 取消已吸附但尚未提交的 Shape 时强制重绘，避免候选残留在 Canvas。

### 识别接受与类型边界

- confidence 默认恢复为 0.2，并严格接受 `confidence > 0.2`。
- Ellipse 先按拟合几何评分，再应用原版近圆归一化：短长轴比 `>0.7`，或平均半径 `<30` 且比值 `>0.5`；
  归一化使用平均半径并将 rotation 归零。
- 原版内部八类为 LINE/ARROW/SQUARE/RECTANGLE/TRIANGLE/POLYGON/ELLIPSE/BEZIERGON；最终持久联合只有
  LINE、POLYGON、NORMAL_SHAPE(ELLIPSE)。ARROW 是 LINE + SINGLE，方形/矩形/三角形和 BEZIERGON 最终都是
  POLYGON。Harmony 现有数据模型足以承载该最终联合，不新增没有 wire 证据的类型。
- 自研主动分类器仍只识别普通 LINE、开放/闭合 POLYGON 和 ELLIPSE；箭头、圆弧与曲线/Beziergon 分类继续作为
  provider 差距，不用经验阈值冒充 MyScript 等价。

## 后果

- 微小手抖不再不断延后吸附；达到原版 pause 窗口后会稳定显示候选。
- 吸附后的继续书写变成原版式 Shape 调整，Up 最终位置不会丢失。
- ellipse confidence、近圆结果和 `>0.2` 边界与原版静态逻辑一致。
- 内部 recognizer 名称不再错误扩大持久模型；后续 provider 可以返回现有 LINE/POLYGON/ELLIPSE 复合结果。
- 8px touch fallback 明确属于 Harmony 适配值，设备实测或未来平台 API 可替换，但不能写成原版 Android 常量。

## 验证契约

- `ShapeHoldLifecycle.test.ets` 覆盖 500ms、tool-specific slop、sub-slop anchor、不合法输入与 reset。
- `ShapeHoldAdjustment.test.ets` 覆盖 LINE 控制点相似变换、5px gate、旋转 Ellipse、Polygon、复合结果、metadata
  保留和 malformed fail-closed。
- `ShapeDetector.test.ets` 覆盖严格 confidence、两条近圆分支、评分先于归一化及大椭圆不误圆化。
- `d02-original-shape-hold-lifecycle.mjs` 同时读取原版与 Harmony source，并执行 pause/circle/LINE/Polygon 数值重放。

## 仍需设备或 provider 验收

- Pen、手指、鼠标在不同 density/系统手写 slop 下的真实抖动阈值与 500ms 手感；Harmony fallback 是否需平台适配。
- 吸附 preview 像素、Up 最终点、Cancel/翻页残影、Undo/Redo、保存重启与 Notability round-trip。
- 原版等价箭头、ellipse/circle arc、curved arrow、Beziergon provider；当前阶段不宣称 MyScript 分类器闭环。
