# 原版 1.4.2 手写识别 HwrEngineService 架构登记（Phase 768 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/handwritingrecognition/`
>   + `com/myscript/iink/` + `defpackage/{k67,l77,n67,gh0,hc3,vdk,pgk}.java`
>   + `resources/AndroidManifest.xml`
> 性质：1.4.2 版本差证据登记 + **Phase 760 结论修正**；无 Harmony 代码变更。

## 一、修正 Phase 760 的判断

Phase 760 依据"MyScript lite 资源删除 + `HwrEngineService` 命名"将 1.4.2
识别定性为**云端识别**。细查后修正：

- `com/myscript/iink/` SDK 仍在（95 个 Java 文件），含 `Engine`/
  `IRecognizerListener`/`Recognizer`；
- `HwrEngineService` 声明 `android:process=":hwr"`——**进程隔离**，
  "Remote" 指跨进程 Binder，非网络；
- `handwritingrecognition/` 与 `myscript/` 全树**无任何 http/网络端点**。

真实架构：本地 iink 引擎独立进程化 + 语言包按需下载。

## 二、IPC 接口（`l77` = IHwrEngine，`k67` = Binder stub）

6 个 Binder 事务（`onTransact` case 1-7）：

| 方法 | 语义 |
|---|---|
| `E(): int` | 引擎能力探测（1/0/-1） |
| `F(long requestId, byte[] samples)` | 按请求 id 流式喂笔迹采样 |
| `I()` | 会话收尾/提交 |
| `l(long)` | 取消/丢弃请求 |
| `t(long): n67` | 取回识别结果 Parcelable |
| `x(long, int, String, String[], int, int, String)` | 会话配置（语言 id、提示词、版面参数） |

服务端将每次调用桥到 `zl4.F` 主线程 + `hc3` 协程，错误经
`RemoteEngineException`/`PenSampleDecodingException` 上抛。

## 三、语言包管道（GMS 边界）

- `HandwritingPackDownloadWorker`：WorkManager 任务，入参 `language_id`。
- `vdk`（SplitInstallInfoProvider）+ `pgk`（AssetPackManager）：
  **Play Asset Delivery** 按需下发语言包。
- 异常族：`LanguagePackUnavailableException`、
  `PlayAssetDeliveryUnavailableException`、
  `HandwritingEngineUnavailableException`、
  `MathRecognitionUnsupportedException`、`RemoteEngineException`、
  `PenSampleDecodingException`。

## 四、与 Phase 765 表的衔接

`FailedInkPage`/`InkPageRecognizer`（noteId+pageKey 复合主键 +
recognizer/language/rawContentFailed）是该引擎的本地记账：
识别失败页排队重试、每页记录所用识别器与语言。

## 五、Harmony 分类

双重 fail-closed：

1. **MyScript iink 闭源 SDK**——无 HarmonyOS 版本，不可移植；
2. **语言包 Play Asset Delivery**——GMS 依赖，Harmony 无等价物
   （Harmony 按需分发体系为 ability-pack 而非资源包下发）。

结论：识别引擎整体维持既有 fail-closed 边界；本阶段仅修正
"云端识别"误述为"进程隔离本地引擎 + Play 按需语言包"。
