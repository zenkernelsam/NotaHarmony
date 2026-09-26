# Phase 825 — uses-permission 逐项差分与 Harmony 映射

## 范围

三版 manifest 权限声明差分 + Harmony `requestPermissions` 逐项映射核验。

## 原版证据

### 版本谱系 19→21→22

- **1.0.3 +2**：`com.google.android.gms.permission.AD_ID` +
  `com.singular.preinstall.READ_PERMISSION_SINGULAR`——817 登记
  Singular 归因栈的权限配套。
- **1.4.2 +1**：`android.permission.READ_CALENDAR`——822 登记的
  CalendarDatabase/syllabus 功能的系统日历读取。

自定义权限 `LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE` 全版本稳定
（守护内容捕获 activity 调用者）。`FOREGROUND_SERVICE` 重复声明 5 次
为 manifest 合并残留。

### 稳定 20 项

INTERNET/NETWORK_STATE/RECORD_AUDIO/CAMERA/READ+WRITE_STORAGE/
WAKE_LOCK/RECEIVE_BOOT_COMPLETED/BIOMETRIC+FINGERPRINT/
FOREGROUND_SERVICE 系（MICROPHONE/MEDIA_PROJECTION/DATA_SYNC）/
READ_PHONE_STATE/CHECK_LICENSE/双渠道 BILLING/BIND_INSTALL_REFERRER/
DYNAMIC_RECEIVER_NOT_EXPORTED。

## Harmony 映射（4 项声明）

INTERNET、KEEP_BACKGROUND_RUNNING（录音长时）、MICROPHONE
（inuse+reason）、READ_PASTEBOARD（inuse+reason，平台新增要求）。

未声明项处置：CAMERA → `cameraPicker` 系统相机免权限；存储 →
文件选择器模型；生物认证 → userIAM 免声明；PHONE_STATE/日历/
Play-GMS 生态 → fail-closed；BOOT_COMPLETED → 卡片框架托管。

## 交付物

- 证据：`docs/migration/evidence/phase-825-permission-inventory.md`
- ADR：`docs/migration/adr/ADR-0769-permission-inventory.md`
- Replay：`docs/migration/replays/d02-permission-inventory.mjs`（10 项断言）

## 验证

- 新增 Replay：10/10 一次通过。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

权限面闭合。候选轴：activity 属性级明细（launchMode/configChanges）、
baseline.prof 抽样、或混淆代码层最后残留（Parcel 类型池/jni 声明）。
