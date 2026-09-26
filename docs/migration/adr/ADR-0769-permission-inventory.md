# ADR-0769 — 权限面闭合：19→21→22 逐项映射

## 状态

已接受。

## 背景

原版 `uses-permission` 逐版清点：1.0.1 为 19 项，1.0.3 增至 21
（`AD_ID`+`READ_PERMISSION_SINGULAR`——Singular 归因上车配套），
1.4.2 增至 22（`READ_CALENDAR`——日历功能配套）。另有一项自定义权限
`LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE` 守护捕获 activity。

Harmony 端 `module.json5` 仅声明 4 项 `requestPermissions`。

## 决定

1. **权限谱系登记**：增量逐项归因已登记集群（Singular/日历）。
2. **picker 模型替代权限**：CAMERA 不声明——`cameraPicker` 系统相机
   UI 在 Harmony 属免权限调用（`OriginalCameraPickerCaller` 承担
   take-photo 通路）；文件存储权限同理由用户文件选择器模型覆盖。
3. **生物认证免声明**：USE_BIOMETRIC/USE_FINGERPRINT 在 Harmony
   由 userIAM 承担，无需 manifest 权限。
4. **生态权限 fail-closed**：READ_PHONE_STATE/CHECK_LICENSE/BILLING/
   AppSet/AD_ID/Singular/READ_CALENDAR 随对应栈整体 fail-closed。
5. **RECEIVE_BOOT_COMPLETED 平台等价**：widget 开机刷新由 Harmony
   卡片框架托管。
6. **保留 Harmony 特有项**：READ_PASTEBOARD（平台要求的剪贴板读取
   声明）与 KEEP_BACKGROUND_RUNNING（长时任务）为平台必需，登记为
   Harmony 侧新声明而非原版缺漏。

## 后果

- 权限面闭合：22 项原版权限逐项落位（等价/picker/免声明/fail-closed）。
- 新增 `d02-permission-inventory.mjs` 回归：谱系、增量、Harmony
  声明集与 cameraPicker 存在性。

## 已验证

- `d02-permission-inventory.mjs`：10/10。
- 全量 Desktop Replay + clean/default、`note@ohosTest` HAP 构建（随 Phase 825 提交）。
