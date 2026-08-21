# ADR-0256：原版手写识别的全局偏好、Harmony Locale 与 Provider 能力边界

## 状态

Accepted - Phase 278（2026-08-21）

## 背景

Phase 274～277 已固定原版 23 组 handwriting language、异步分笔迹/force provider 契约、选区适配、Convert-to-
Text planner 与 type-25/type-22/type-8 原子持久化。生产路径仍缺两项容易被错误移植的边界：

1. 原版全局识别语言偏好不在 note metadata 或 `noteEditorSettings`，而在独立
   `handwritingRecognitionSettings` DataStore 的 `recognitionLanguageId` 键；`fr2 case 11` 保存的是
   `dc5.I` 完整 locale code，而不是 `dc5.J` canonical language tag。
2. Harmony CoreVision OCR 能识别图片中的印刷文字，但不接受原版要求的有序 pointer stroke/force，也不能把
   指定 `dc5.I` 锁定到一次调用。将它直接伪装成手写 provider 会产生错误结果和错误产品可用性。

## 决策

### 1. 独立 preference store 与 exact canonicalization

新增 `OriginalHandwritingLanguagePreferenceStore`：

- 精确复用原版 store/key：`handwritingRecognitionSettings` / `recognitionLanguageId`；
- 读值必须是 string 且命中既有 23 组 exact locale code 或 language tag；未知/错类型返回 null；
- 写值允许 UI/调用者传任一 exact 形式，但落盘一律 canonicalize 为 `dc5.I`（如 `zh_TW`）；
- `put()` 或 `flush()` 失败时尝试恢复旧值或删除新键；只有补偿 mutation 成功才 flush，并报告
  commit/rollback 双失败；
- storage 生命周期内显式复用同一个 Harmony `Preferences` 实例；首次获取失败会清空缓存并允许重试；
- 使用独立静态 `AsyncMutex`，不与 `noteEditorSettings` 混用。

### 2. Harmony Locale 只作为可注入适配层

新增 `OriginalHandwritingLocaleAdapter`：

- 生产 source 使用 `@kit.LocalizationKit` 的 `i18n.System.getSystemLanguage()` 与
  `i18n.System.getSystemLocale()`；
- 纯函数解析 BCP-47 language/script/region，适配成已有 `OriginalLocaleLanguage`；
- 空值、Android 下划线格式、未知 variant/extension/private-use 子标签、冲突字段及系统 API 异常输出空字段；不得猜测 `en_GB → en_US` 或其它邻近
  locale；
- `OriginalHandwritingRecognitionContextAdapter` 按原版顺序组合：当前 note metadata register → 独立全局
  preference → Harmony system Locale → 既有 policy 的英文默认。

### 3. CoreVision 仅做 capability policy，不做伪 provider

新增 `OriginalHandwritingProviderCapabilityPolicy`：

- 记录 `SystemCapability.AI.OCR.TextRecognition` 与官方 CoreVision image/OCR 语义；
- capability 必须同时具备 stroke-native 输入、force 保留、per-call locale code 与完整 23 组覆盖，才可被
  判定为原版 provider；
- CoreVision 的固定评估结果为 incompatible（图片 PixelMap、无 pointer/force、配置无法锁定语言、官方
  语言集合不等价）；
- capability probe（例如 `canIUse`）由上层注入，纯 policy 可在静态 Replay 中复现；
- 在有真实 provider 前，不增加 SelectionOverlay “转文字”入口、不把 CoreVision 图片 OCR 结果写回 Text。

## 后果

正面：

- global preference 的文件/key/value 与原版一致，且不会污染 note metadata；
- Locale 适配可独立 fixture，系统异常时 fail closed；
- 不会因系统存在某个 OCR syscap 就错误宣称手写转文字可用；
- 未来真实 provider 接入时已有正确的 note/global/system context 与能力门禁。

代价与未闭环项：

- 尚无真实 stroke-native OCR 模型/provider、生产 page/frame/fingerprint 采集和 SelectionOverlay 入口；
- CoreVision 仍可在未来作为独立“图片印刷品 OCR”能力评估，但不能复用原版手写接口；
- Locale 变更监听、设置 UI 与设备端正确率/时延/内存仍待后续阶段和用户明确设备测试。

## 验证

- 原版 JADX source、fr2 单类 debug extraction、Harmony LocalizationKit/CoreVision SDK hash 见
  `docs/migration/evidence/original-handwriting-context-adapter-jadx-sdk-2026-08-21.md`；
- ArkTS fixture：`note/src/test/OriginalHandwritingLocaleAdapter.test.ets`；
- 专项 Replay：`docs/migration/replays/d02-original-handwriting-context-adapter.mjs`；
- 不启动模拟器、虚拟机、真机或 Hypium。
