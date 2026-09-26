# Phase 768 — 原版 1.4.2 HwrEngineService 架构登记与修正

日期：2026-09-29
状态：完成（证据修正 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-768-original-hwr-service.md`
ADR：`ADR-0712-original-hwr-service.md`
Replay：`d02-original-hwr-service.mjs`（8/8）

## 本阶段做了什么

细查 1.4.2 新增 `HwrEngineService`——Phase 760 曾据 lite 资源删除
将其定性为"云端识别"。本阶段证据链修正该判断。

## 恢复的架构

- `HwrEngineService` 以 `android:process=":hwr"` 独立进程运行，
  `onBind` 返回 `k67`（`IHwrEngine` Binder stub，描述符
  `com.gingerlabs...hwr.IHwrEngine`）。
- `l77` 接口六事务：`E()` 能力探测、`F(id,bytes)` 流式喂笔迹、
  `I()` 收尾、`l(id)` 取消、`t(id)` 取结果、`x(...)` 会话配置
  （语言 id + 提示 + 版面参数）。
- `com/myscript/iink` SDK 全量在包（95 文件），识别仍在设备端；
  `RemoteEngineException` 的 Remote 指跨进程而非网络。
- 语言包按需下发：`HandwritingPackDownloadWorker`（language_id 入参）
  + `SplitInstallInfoProvider`/`AssetPackManager` = Play Asset Delivery；
  配套异常族（LanguagePackUnavailable/PlayAssetDeliveryUnavailable/
  HandwritingEngineUnavailable/MathRecognitionUnsupported）。
- `handwritingrecognition/` + `myscript/` 全树零网络端点。

## 修正与分类

- Phase 760/767 中"远端 HWR"表述经 ADR-0712 修正为
  "进程隔离本地引擎 + Play 按需语言包"；相关文档已加注。
- 双重 fail-closed：MyScript iink 闭源（无 Harmony 版）+
  Play Asset Delivery 属 GMS（Harmony 无等价物）。不移植。
- Phase 767 的 FailedInkPage/InkPageRecognizer 分类不变
  （引擎缺席则记账表无消费者）。

## 验收

- Replay 8/8 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新；ADR-0708/0711 与 Phase 760/767 证据已加注修正。
