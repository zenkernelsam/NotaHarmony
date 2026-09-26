# ADR-0712 — 原版 1.4.2 HwrEngineService 架构修正与双重 fail-closed

日期：2026-09-29
状态：已登记（证据修正 + fail-closed 维持；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-768-original-hwr-service.md`
Replay：`docs/migration/replays/d02-original-hwr-service.mjs`
修正对象：ADR-0708 证据中"远端 HWR"表述

## 背景

Phase 760 依据 MyScript lite 资源删除将 1.4.2 识别定性为云端识别。
Phase 768 细查证明该判断不准确：

- `com/myscript/iink` SDK（95 文件）仍在包内；
- `HwrEngineService` 以 `android:process=":hwr"` 运行——"Remote" 指
  跨进程 Binder（`l77`=IHwrEngine，六事务），非网络调用；
- `handwritingrecognition/` 与 `myscript/` 全树无网络端点。

真实架构：**本地 iink 引擎进程隔离化** + 语言包经 Play Asset
Delivery 按需下发（`HandwritingPackDownloadWorker` + language_id）。

## 决策

1. **修正证据表述**：1.4.2 为"进程隔离本地引擎 + Play 按需语言包"，
   非云端识别。Phase 760/767 中"远端 HWR"字样按本 ADR 解读。
2. **双重 fail-closed**：MyScript iink 闭源（无 Harmony 版本）+
   Play Asset Delivery 为 GMS 依赖（Harmony 无等价按需资源包）。
   识别引擎不移植，文字/数学转文本入口维持既有注册边界。
3. `FailedInkPage`/`InkPageRecognizer`（Phase 767）归类不变——
   本地记账服务于该引擎，引擎缺席即无消费者。

## 后果

- 本 ADR 为 T-042 提供准确的架构级版本差描述。
- Replay 钉住 `:hwr` 进程声明、IHwrEngine 方法签名、iink 在场
  与 Play 语言包管道证据。
