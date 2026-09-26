# Phase 830 — queries/uses-feature 明细

## 范围

三版 manifest 的 `<queries>` 与 `<uses-feature>` 逐元素解析。

## 原版发现

### `<queries>`（包可见性）

7 个 intent action + 3 个 package：

- 基线（1.0.1 起）：SEND、MAIN、InAppBilling BIND、
  BillingTestCompanion BIND（测试伴生服务随发布包）；
  package 仅 samsungapps。
- **1.0.3 新增**：Singular preinstall intent + katana/instagram
  包（Phase 817 归因链路）。
- **1.4.2 新增**：`IMAGE_CAPTURE_SECURE`——锁屏相机 intent
  探测，与 Phase 826 的 `showWhenLocked`/`turnScreenOn`
  MainActivity 属性构成完整锁屏拍照链路。

### `<uses-feature>`（三版全同）

camera.any / camera / camera.autofocus / camera.flash /
screen.portrait / screen.landscape —— 全部 `required=false`
（可选硬件声明，不做商店过滤）。

## Harmony 侧

无 `<queries>` 等价物（包可见性模型不同）；`deviceTypes`
承担设备形态声明；相机走 cameraPicker 系统组件。

## 验证

- 新 Replay `d02-queries-features.mjs`：**12/12**（三版
  intent/package 明细、IMAGE_CAPTURE_SECURE 独有性、
  六 feature 可选断言）。
- ADR-0774。**manifest 元素层至此全部闭合**。
