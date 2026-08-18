# 修复总结：Phase 274 原版手写识别语言与异步 Provider 边界

## 1. 基线与纪律

- 唯一可写工程：`C:\HarmonyProject\NotaHarmony`；Desktop `Notability` 仅用于读取原版 APK、JADX 与临时
  DEX 证据。
- 阶段基线 `HEAD=3c5d3c3d414b1f75f48ea49319952b277f01e06f`，`main` 比 `origin/main`
  `6f5201105e4fc994e2deeac6d4e3cb6c8833e488` 超前 2 个提交；Phase 264～266 已再次确认完整位于
  `c1be5f0d9346f7c05547a0f39ac32fd36345aeaa`，且该提交是当前 HEAD 祖先。
- 既有 `.codex-tmp-*`、`.hvigor-user-phase270/271/272`、`Chat History/` 与
  `note/oh-package-lock.json5` 均未删除、未提交；本阶段不 push。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 2. 原版结论

直读 `dc5/sh8/jc5/hc5/pm8/l2d` 并以 APK DEX 修正损坏 switch 后确认：

1. 识别语言依次取当前笔记 register、全局偏好、系统 Locale，最后回退 `en_US/en`；
2. note/global 值只 exact match `dc5.I` 或 `dc5.J`，`en_GB` 不会被猜成 `en_US`；
3. 中文按 `Hant/Hans` 优先，其次以 `TW/HK/MO` 判断繁体；
4. DEX 明确 `no/nn → nb`、`tl → fil`、`in → id`；
5. MyScript 的 `lang` 与 `recognizer.lang` 消费 `dc5.I` 完整 localeCode；
6. `pm8.a()` 对每条选中 Ink 独立发送 pointer down/move/up 并保留 force，`pm8.c()` 是 coroutine。

完整 hash、行号、APK 与 DEX 片段见
`docs/migration/evidence/original-handwriting-language-resolution-jadx-dex-2026-08-18.md`。

## 3. 实现内容

### 3.1 原版语言 policy

新增 `OriginalHandwritingLanguagePolicy.ets`：

- 固定 23 组 `dc5 localeCode/languageTag`；
- 保留 note/global/system/default 四级来源与来源枚举；
- exact lookup 不大小写折叠、不推断邻近地区；
- 恢复中文 script/region 与 `no/nn/tl/in` 映射；
- unsupported system Locale 回退英文。

### 3.2 独立异步 OCR provider 边界

新增 `OriginalHandwritingRecognition.ets`：

- provider 与 ShapeDetector/旧 `RecognitionProvider` 分离；
- 输入保留多条 stroke 的顺序、边界、page-space position 与 force；
- `recognizeText()` 返回 Promise，并只传完整 `localeCode`；
- provider 缺席、不可用或空选区时返回 null；
- provider 返回空字符串时保留空字符串，返回 null 时不伪造结果。

旧 `RecognitionProvider.recognizeText(Point2D[])` 因 phase-1 契约不能改签名，现明确标注为同步扁平点占位，
禁止生产 OCR 复用 ShapeDetector 可用性。

## 4. 边修边补审发现

第一版新边界虽然补了语言参数，却仍沿用旧同步 `Point2D[]`。继续追到 `pm8.a/e` 后发现这会同时丢失三项原版
事实：每条 Ink 的 pointer 生命周期、逐点 force，以及 suspend/coroutine 调度。现已在文档落盘前改为异步
`OriginalHandwritingRecognitionStroke[]`，fixture 锁定两条 stroke 不被拼接并保留 force。

本轮没有继续猜造 `StrokeElementData → page-space samples` 适配。原版还依赖 page frame、Ink transform、center
path verb 与单笔 decode failure；这些需要独立证据和真实 provider 后再接，当前保持 fail closed。

## 5. Fixture、证据与 Replay

- `note/src/test/OriginalHandwritingRecognition.test.ets`：exact priority、中文、legacy alias、英文 fallback、
  provider gate、异步调用、分笔迹/force、localeCode、空文本与 null。
- `docs/migration/replays/d02-original-handwriting-language-resolution.mjs`：原版 hash/JADX/DEX、Harmony policy、
  provider boundary 与 fixture 注册门禁。
- ADR：`docs/migration/adr/ADR-0252-original-handwriting-language-provider-boundary.md`。
- Desktop 临时 DEX：`.codex-tmp-phase274-dex/classes.dex`，大小 `7,469,228`，SHA-256
  `6425BCDD11AA94AA3E6ECCFBCCDDE70B08F451C96CEC34CCD947F26BC26F8819`；不进入 Harmony Git。

## 6. 验证结果

| 门禁 | 结果 |
|---|---|
| Phase 274 专项 Replay | `D02_ORIGINAL_HANDWRITING_LANGUAGE_OK TOTAL=25 FAILED=0` |
| metadata/recognition 相关 Replay | `RELATED_REPLAY_FILES=7 PASSED=7 FAILED=0` |
| 全量 Desktop Replay | `REPLAY_FILES=259 PASSED=259 FAILED=0` |
| 增量 `note@ohosTest` | `BUILD SUCCESSFUL in 11 s 915 ms` |
| `git diff --check` | 通过（仅 Windows 换行转换提示） |
| clean | `BUILD SUCCESSFUL in 2 s 433 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 7 s 755 ms` |
| clean 后 `note@default` | `BUILD SUCCESSFUL in 48 s 209 ms` |

第一次尝试使用尚未完整安装 wrapper 的 `.hvigor-user-phase272` 时，Hvigor 在进入项目/ArkTS 前因自身 pnpm
bootstrap 路径判断失败；改用上一阶段已验证的 `.hvigor-user-phase271` 并显式指定 DevEco bundled Node 后成功。
该次失败不是源码编译结果。default 终验只有项目既有 ArkTS exception/deprecation 与 unsigned-signing warning。

## 7. 阶段边界与后续

本阶段闭环的是原版识别语言选择与不会误导未来实现的 provider 契约，不宣称手写转文字已经可用。仍开放：

- Harmony Locale API 与全局 handwriting preference adapter；
- 真实 OCR provider、模型资源/下载/离线可用性；
- `StrokeElementData`/选区到 page-space recognition strokes 的转换与错误隔离；
- 选区菜单入口、识别结果写回、版面布局、Undo/Redo 和搜索索引更新；
- 设备交互、正确率、时延、内存、异常提示与多语言体验。

`T-042` APK 版本追踪继续严格留到整个 Goal 最后一项。
