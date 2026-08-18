# ADR-0252：原版手写识别语言解析与异步 Provider 边界

## 状态

Accepted - Phase 274（2026-08-18）

## 背景

Phase 270～273 已保留当前笔记的 handwritingLanguage register、原版出站与持久历史，但工程仍只有旧
`RecognitionProvider.recognizeText(Point2D[])` 占位签名。该签名没有语言参数，并与 ShapeDetector 共用
`isAvailable()`；若直接拿它接生产 OCR，会把“几何 ShapeDetector 可用”误当成“手写文字模型可用”。

原版调用链为 `jc5.e → sh8.D → hc5 → pm8.c/b`。它不仅要求精确选择 `dc5` 语言，还通过 coroutine 对每条
选中 Ink 分别发送 pointer down/move/up，并保留 force。Harmony 若只补一个同步、扁平 `Point2D[]` provider，
会在真正接 OCR 前先固化错误的数据与调度契约。

## 决策

### 1. 固定原版 23 组识别语言

`OriginalHandwritingLanguagePolicy` 固定 `dc5` 的 23 组 `(localeCode, languageTag)`。输入查找只执行原版
大小写敏感 exact match：完整 `localeCode`（如 `zh_TW`）或 canonical tag（如 `zh-Hant`）可命中；`en_GB`
等仅通过 metadata ISO prefix 校验、却不在 `dc5` 中的值不能被猜成邻近模型。

### 2. 保留四级来源优先级

解析顺序固定为：

```text
recognized note register
→ recognized global preference
→ mapped system Locale
→ en_US/en
```

中文系统 Locale 先看 script：`Hant` 为繁体、`Hans` 为简体；script 未明确时 `TW/HK/MO` 为繁体，其余为
简体。APK DEX 纠正损坏 JADX switch 后，`no/nn → nb`、`tl → fil`、`in → id`。

### 3. Provider 消费 localeCode，而不是 languageTag

MyScript 同时把 `dc5.I` 写入 `lang` 与 `recognizer.lang`。因此 provider 必须接收完整 `localeCode`，例如
`zh_TW`；`dc5.J` 只用于 exact lookup/canonical tag，不能代替模型配置值。

### 4. 新边界必须异步并保留笔迹分段与 force

新增独立 `OriginalHandwritingRecognitionProvider`：

- `recognizeText()` 返回 `Promise<string | null>`，对应原版 suspend/coroutine 路径；
- 输入为有序 `OriginalHandwritingRecognitionStroke[]`；
- 每条 stroke 保存独立 samples，sample 含 page-space position 与 force；
- 不允许把多条 Ink 拼成一条折线，也不复用旧同步 `Point2D[]` 占位签名。

当前阶段只定义正确边界；`StrokeElementData` 的 transform/page-frame 归一化、坏 center path 的逐笔
`pointerCancel` 等由未来 selection adapter/provider 实现。

### 5. 没有真实 Provider 时 fail closed

provider 缺席、provider 不可用或选区为空时返回 null，不调用任何识别实现。ShapeDetector 的
`isAvailable()` 只代表几何形状分类器可用，不得提升为 OCR 能力；旧 `RecognitionProvider.recognizeText()`
保留兼容签名，但注释明确禁止生产 OCR 使用。

## 后果

正面：

- note/global/system/default 语言选择与原版一致；
- 合法但不受支持的 metadata 值不会误选模型；
- 中文与 Java legacy locale alias 有 APK bytecode 门禁；
- 未来 provider 已有正确的异步、分笔迹、force 与 `localeCode` 契约；
- 当前无 provider 时不会伪造 OCR 可用性或结果。

代价与限制：

- 尚无 Harmony Locale API adapter 与全局 handwriting preference；
- 尚无 MyScript、系统 OCR 或其他生产 provider；
- 尚无选区到 page-space recognition strokes 的 adapter、选区“转文字”入口、结果写回与 Undo；
- 设备模型下载、离线可用性、时延、错误提示、文字布局与搜索索引更新均未验收。

## 验证契约

- 原版 JADX hash、APK hash 与损坏 switch 的 DEX 事实必须由专项 Replay 固定；
- 23 组语言、exact lookup、四级优先级、中文和 `no/nn/tl/in` 必须有纯逻辑 fixture；
- fixture 必须覆盖 provider 缺席/不可用/空选区、异步返回、空文本、null、分笔迹/force 与 `localeCode` 透传；
- metadata、Shape recognition 与搜索相关 Replay 不能回归；
- 全量 Replay、`git diff --check`、clean 后两套 HAP 必须通过；不得启动设备、模拟器、虚拟机、真机或 Hypium。
