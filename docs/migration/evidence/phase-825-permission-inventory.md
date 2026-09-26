# Phase 825 — uses-permission 逐项差分与 Harmony 映射

证据来源：三版 `AndroidManifest.xml` `uses-permission`/`permission` 声明；
Harmony `module.json5` `requestPermissions` 与 `OriginalCameraPickerCaller`。

## 一、版本谱系（19 → 21 → 22）

| 版本 | 应用声明数 | 增量 |
|---|---|---|
| 1.0.1 | 19 | — |
| 1.0.3 | 21 | +`AD_ID`（GMS 广告 ID）+`READ_PERMISSION_SINGULAR`（Singular 预装归因）——817 登记的 Singular 上车配套 |
| 1.4.2 | 22 | +`READ_CALENDAR`——822 CalendarDatabase/syllabus 功能的系统日历读取 |

另有应用自定义权限 `LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE`
（全版本，守护内容捕获 activity 的调用者身份）。

`FOREGROUND_SERVICE` 在每版 manifest 中重复声明 5 次（merge 产物去重
未净），登记为构建残留非语义。

## 二、稳定权限清单（20 项全版本）

INTERNET / ACCESS_NETWORK_STATE / RECORD_AUDIO / CAMERA /
READ+WRITE_EXTERNAL_STORAGE / WAKE_LOCK / RECEIVE_BOOT_COMPLETED /
USE_BIOMETRIC + USE_FINGERPRINT / FOREGROUND_SERVICE(+MICROPHONE/
MEDIA_PROJECTION/DATA_SYNC) / READ_PHONE_STATE / CHECK_LICENSE /
BILLING（Play+Samsung IAP）/ BIND_GET_INSTALL_REFERRER_SERVICE /
DYNAMIC_RECEIVER_NOT_EXPORTED（自定义）

## 三、Harmony `requestPermissions`（4 项）映射

| Harmony 权限 | 原版对应 | 判定 |
|---|---|---|
| INTERNET | INTERNET | 等价 |
| KEEP_BACKGROUND_RUNNING | FOREGROUND_SERVICE + WAKE_LOCK | 录音长时任务（820） |
| MICROPHONE（inuse + reason） | RECORD_AUDIO | 等价，Harmony 用 inuse 场景声明更严格 |
| READ_PASTEBOARD（inuse + reason） | —（Android 无对应声明） | Harmony 平台要求，新增 |

### 原版有声明、Harmony 未声明的处置

| 原版权限 | Harmony 处置 |
|---|---|
| CAMERA | `cameraPicker` 系统相机 UI 捕获（`OriginalCameraPickerCaller`），**无需权限**——平台模型更优 |
| READ/WRITE_EXTERNAL_STORAGE | Harmony 文件选择器模型，无存储全量权限 |
| USE_BIOMETRIC/USE_FINGERPRINT | userIAM 生物认证 API，无需 manifest 声明 |
| READ_PHONE_STATE | Singular 设备标识读取——随归因栈 fail-closed |
| READ_CALENDAR | 日历后端功能 fail-closed，对应权限不声明 |
| RECEIVE_BOOT_COMPLETED | widget 启动刷新由 Harmony 卡片系统托管 |
| CHECK_LICENSE/BILLING/AppSet/ref errer | Play/GMS 生态 fail-closed |
| FOREGROUND_SERVICE_* / WAKE_LOCK | KEEP_BACKGROUND_RUNNING 覆盖 |

## 四、结论

权限面闭合：原版 19→21→22 逐项登记（增量全部归因已登记集群），
Harmony 4 项声明全部有原版对应或平台必需；未声明项逐一登记
处置理由（picker 模型 / fail-closed / 机制等价），无权限空洞。
