# ADR-0253：原版手写选区到 pointer stroke 的 Harmony 适配

## 状态

Accepted - Phase 275（2026-08-18）

## 背景

ADR-0252 已固定原版识别语言和异步 provider 契约，但仍缺少从 Harmony 当前选区到
`OriginalHandwritingRecognitionStroke[]` 的数据转换。原版 `jc5/pm8` 并不接收一条扁平折线：
它按实体 identity 排序、按 Ink 分段发送 pointer down/move/up，叠加 page-frame origin，保留
每个采样的 force，并允许单笔 center-path 解码失败后 cancel 当前笔再继续。

Harmony 的 `StrokeElementData` 已把页面坐标和局部 transform 分开保存，且导入 Notability
笔画使用 `nb-*` 非 operation ID。若把 transform 忽略、把 imported ID 当损坏、或把所有 path
拼成一条线，未来接入真实 provider 时会先固化错误的识别几何和笔序。

## 决策

### 1. 使用独立纯逻辑 adapter

新增 `OriginalHandwritingSelectionAdapter.ets`，输入当前页面的 `selectedStrokeIds` 与
`StrokeElementData[]`，输出：

- 有序、深拷贝的 `OriginalHandwritingRecognitionStroke[]`；
- 与输出一一对应的 `acceptedStrokeIds`；
- 每个被跳过 ID 及明确 `OriginalHandwritingSelectionSkipReason`。

不在 adapter 内调用 provider、修改 SelectionTool、写回文本或触碰 UI 状态。

### 2. 过滤和失败隔离

只接受 finished、非 partial-eraser、非 highlighter、非空 center path，并要求完整的、非奇异
3×3 affine 与有限的 sample position/pressure。任何单条笔画失败只产生一个 skipped entry，
其他笔画继续；全部失败时由上层 provider gate 返回 null。

原版 page frame/隐藏过滤发生在其页面实体层。Harmony adapter 的输入契约是“当前可见页面的
已解析数组”，不在缺少等价实体注册表时伪造隐藏状态或跨页 frame。

### 3. 坐标和 force

对每个 path sample 应用完整行主序 affine：`(m0*x+m1*y+m2, m3*x+m4*y+m5)`。`pressure`
原样映射为 provider `force`，`-1` 表示无能力时保持 `-1`；不使用 widthFactor、bounds 或
世界 AABB 替代中心路径。

### 4. identity 顺序

可解码的 `op:timestamp:site` ID 使用既有 `decodeOperationId()` 与
`compareOperationIdentity()`，等价于原版 unsigned `(timestamp, siteId)`。不可解码的
imported ID 不猜造 identity：canonical 候选只在自身原槽位中重排，imported 槽位保持输入顺序。
这使全 canonical 页面与原版一致，同时避免 `NotabilitySessionParser` 导入笔迹因非 canonical
ID 被整批拒绝。

## 后果

正面：

- 未来异步 provider 已有正确的分笔迹、page-space、force 和 deterministic order 输入；
- selection transform、旋转/翻转/剪切等完整 affine 不会静默丢失；
- malformed/unfinished/highlighter/partial 笔迹不会污染其他笔迹；
- imported `nb-*` 笔迹仍可被未来 OCR 消费，且没有伪造原版 operation clock。

代价与开放项：

- 当前尚无真实 OCR provider、选区入口、结果写回/Undo 或搜索索引更新；
- 可见性/page-frame 仍要求调用者传入正确的当前页面集合；
- center path 已在 Harmony 解码层完成，不能在 adapter 中复现原版逐个 path verb 的异常类型；
  malformed sample 以整笔 fail closed 作为等价安全边界；
- 设备正确率、时延、模型资源和错误提示仍未验收。

## 验证

- 原版 `jc5/rn2/so5/wqh/pm8/bmb/fqa/s06` hash、行号和行为固定于对应 evidence 与 Replay；
- ArkTS fixture 覆盖 canonical/imported 顺序、完整 affine、force `-1`、过滤、逐笔错误隔离、
  duplicate/ambiguous ID；
- 专项 Replay、相关 Replay、全量 Replay、clean 后双 HAP 和 `git diff --check` 必须通过；
- 不启动模拟器、虚拟机、真机或 Hypium。
