# 修复总结：Phase 278 原版手写全局偏好与 Harmony Locale 能力边界

## 1. 阶段范围与工作区纪律

- 唯一修改工程为 `C:\HarmonyProject\NotaHarmony`。
- `C:\Users\Cisco He\Desktop\Notability` 只读取原版 APK、`decompiled_1.0.3` 与临时 JADX 证据；没有在
  Desktop 创建或维护 Harmony 源码工作树。
- 本阶段承接 Phase 274～277 的语言 policy、pointer stroke 适配、转换 planner 和原子持久化，收口原版
  global preference 与 Harmony system Locale 的生产 context，并明确平台 OCR 能力边界。
- 未启动模拟器、虚拟机、真机或 Hypium；`T-042` APK 版本追踪继续保留到整个 Goal 最后一项。

## 2. 原版 1.0.3 静态证据

直读 `kc5/xr/tc/fr2` 并以同 APK 的 JADX 单类 debug extraction 补足损坏方法后确认：

1. 全局识别语言保存在独立 DataStore：
   `handwritingRecognitionSettings/recognitionLanguageId`，不是 `noteEditorSettings`，也不是 note metadata。
2. `fr2 case 11` 写入的是 `dc5.I` 完整 locale code，例如繁体中文为 `zh_TW`；`dc5.J` 的
   `zh-Hant` 只用于 exact lookup/display，不能作为原版持久化值。
3. 原版解析顺序继续是：当前 note handwriting register → global preference → system Locale → `en_US`。

原版文件、JADX extraction、Harmony SDK 与 DevEco 离线 API Reference 的 SHA-256、行号和片段见
`docs/migration/evidence/original-handwriting-context-adapter-jadx-sdk-2026-08-21.md`。

## 3. 实现内容

### 3.1 独立 global preference store

新增 `OriginalHandwritingLanguagePreferenceStore.ets`：

- 精确使用原版 store/key；
- 读取只接受 string，且必须 exact 命中 Phase 274 固定的 23 组 `dc5.I` 或 `dc5.J`；未知值和错类型返回
  `null`，交给既有四级 policy 继续回退；
- 写入允许调用者传 exact locale code 或 language tag，但统一 canonicalize 为 `dc5.I` 后落盘；
- `put()` 与 `flush()` 都纳入补偿事务，失败时尝试恢复旧值或删除新键；只有补偿 mutation 成功才再次
  flush，commit/rollback 双失败会明确向上报告；
- 读、写、删、flush 显式复用同一个 Harmony `Preferences` 实例，首次获取失败会清除缓存 Promise 以允许
  后续重试；所有公开操作由独立静态 `AsyncMutex` 串行化。

### 3.2 Harmony LocalizationKit 适配

新增 `OriginalHandwritingLocaleAdapter.ets`：

- 生产 source 调用 `i18n.System.getSystemLanguage()` 与 `getSystemLocale()`；
- 纯函数解析官方 BCP-47 返回格式，包括 `zh-Hans` 与 `zh-Hans-CN`，再转换为既有
  `OriginalLocaleLanguage`；
- 空串、前后空白、Android 下划线格式、未知 variant/extension/private-use 子标签、重复 script/region、language/script/region 互相冲突及平台异常均
  fail closed，不猜测邻近国家或语言。

新增 `OriginalHandwritingRecognitionContextAdapter.ets`，从既有 metadata winner state 读取 note register，
再组合独立 global preference 与 Harmony Locale；最终仍调用 Phase 274 的原版解析 policy。

### 3.3 CoreVision capability 门禁

DevEco 离线 API Reference 与 SDK 证明 CoreVision 通用文字识别面向票据、卡证、表格、报刊、书籍等印刷品，
输入是 RGBA_8888 `PixelMap`，syscap 为 `SystemCapability.AI.OCR.TextRecognition`。它没有原版 provider
所需的有序 pointer down/move/up、force、调用级 `dc5.I` 锁定和完整 23 组覆盖。

因此新增 `OriginalHandwritingProviderCapabilityPolicy.ets`，把 CoreVision 固定评估为 incompatible；即使
设备报告 syscap 可用，也不得把图片 OCR 伪装成 `OriginalHandwritingRecognitionProvider`。本阶段没有新增
SelectionOverlay “转文字”菜单，也没有把 CoreVision 结果写入 Text。

## 4. 边修边补审发现与处理

- 初版 preference transaction 把 `put()` 放在 commit catch 外；若平台 mutation 阶段抛错，补偿不会执行。
  现已把 `put()` 与 `flush()` 统一纳入事务，并增加 put-failure fixture。
- 收尾补审发现补偿 mutation 失败后继续 flush 会把未知内存状态落盘；现仅在补偿 mutation 成功时 flush，
  双失败直接报告 rollback failure 并等待后续恢复，不伪装数据已恢复。
- 初版 storage 每个方法重新调用 `getPreferences()`；SDK 虽说明同文件在内存中只有一个实例，但显式复用能
  保证同一 transaction 的 has/read/put/delete/flush 使用稳定对象，并能准确处理首次获取失败。
- 初版 Locale 只拒绝 language 冲突；现补齐双方同时携带但不一致的 script/region 冲突门禁，避免
  `zh-Hans + zh-Hant-TW` 或 `en-US + en-GB` 被错误拼接。
- 收尾补审又发现未知 BCP-47 variant/extension/private-use 子标签会被静默忽略；现改为直接 fail closed，
  避免从 `en-US-x-private` 等超出生产需要的输入猜出受支持 locale。
- 历史总纲仍把 Locale/global adapter 记为开放项；本阶段只关闭适配层，不把真实 provider、产品 caller 或
  UI 入口误报为完成。

## 5. Fixture、Replay 与文档

- 新增 `OriginalHandwritingLocaleAdapter.test.ets` 并注册到 `List.test.ets`；覆盖 BCP-47、异常/冲突、四级
  context、`dc5.I` canonicalization、put/flush rollback 与 CoreVision capability gate。
- 新增专项 Replay：`docs/migration/replays/d02-original-handwriting-context-adapter.mjs`。
- 新增 ADR-0256 与原版/JADX/SDK/离线 HTML evidence。
- 更新 `修复总纲.md`、`修复总纲2.md` 与 `修复进展-2026-08-09.md`，更正 Phase 274～277 的历史开放项。

## 6. 验证结果

- 专项 Replay：`D02_ORIGINAL_HANDWRITING_CONTEXT_OK TOTAL=22 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=263 PASSED=263 FAILED=0`。
- `git diff --check` 通过。
- 在 `.hvigor-user-phase271` 下严格串行终验：clean `BUILD SUCCESSFUL in 2 s 113 ms`；
  `note@ohosTest` `BUILD SUCCESSFUL in 8 s 417 ms`；`note@default`
  `BUILD SUCCESSFUL in 1 min 1 s 803 ms`。
- 生成 unsigned HAP：ohosTest `6,490,159` bytes，default `25,932,083` bytes；仅有项目既有
  ArkTS exception/deprecation 与未配置 signing 的 warning，没有 Phase 278 编译错误。
- 全部验证只做静态读取、Node Replay、ArkTS fixture 编译和 HAP 打包，不运行任何设备或 Hypium。

## 7. 明确保留的开放边界

本阶段完成的是底层 preference、Locale、context 与 capability policy，不代表手写转文字产品功能上线。
以下仍开放：

- 真实 stroke-native OCR 模型/provider 与完整 23 组语言实测；
- SelectionOverlay 入口、生产 page/frame/source fingerprint 采集和 caller 编排；
- provider 结果接入 Phase 276/277 planner/persistence、错误提示与产品状态；
- 设置 UI、Locale 变更监听、真实旧偏好迁移与设备正确率/时延/内存验收。

Phase 275 的页面可见性/page-frame 解析边界及 Phase 277 的底层 API 无产品 caller 现状同样保持，不以静态
HAP 构建冒充运行态完成。`T-042` 继续严格留到 Goal 最后一项。
