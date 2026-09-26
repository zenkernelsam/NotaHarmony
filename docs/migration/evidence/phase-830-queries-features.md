# Phase 830 — `<queries>` 与 `<uses-feature>` 明细

证据：三版 `resources/AndroidManifest.xml` 逐元素解析

## 一、`<queries>` 明细（包可见性声明）

| Intent action / package | 1.0.1 | 1.0.3 | 1.4.2 | 归因 |
|------------------------|:-----:|:-----:|:-----:|------|
| `SEND` | ✓ | ✓ | ✓ | 分享目标可见性 |
| `MAIN` | ✓ | ✓ | ✓ | launcher 查询 |
| `InAppBillingService.BIND` | ✓ | ✓ | ✓ | Play Billing 绑定 |
| `BillingOverrideService.BIND` | ✓ | ✓ | ✓ | Billing 测试伴生服务（随发布包） |
| `READ_PERMISSION_SINGULAR` | — | ✓ | ✓ | **1.0.3 新增** Singular 预装归因（817 链路） |
| `IMAGE_CAPTURE_SECURE` | — | — | ✓ | **1.4.2 新增** 锁屏相机 intent 探测 |
| `com.sec.android.app.samsungapps` | ✓ | ✓ | ✓ | 三星商店 |
| `com.facebook.katana` / `com.instagram.android` | — | ✓ | ✓ | **1.0.3 新增** FB/IG 分享目标（817） |

**关联 Phase 826**：`IMAGE_CAPTURE_SECURE` 与 MainActivity
`showWhenLocked`/`turnScreenOn` 同属锁屏拍照链路——1.4.2 为该
流程补充了安全相机可见性声明。

## 二、`<uses-feature>` 明细（三版全同，均 required=false）

`camera.any`、`camera`、`camera.autofocus`、`camera.flash`、
`screen.portrait`、`screen.landscape` —— 全部可选：原版不硬要求
相机/方向硬件，商店过滤不限制。

## 三、Harmony 侧

- Harmony 无 `<queries>` 等价物——`bundleManager.canOpenLink` /
  显式 want 不依赖包可见性清单；第三方应用探测模型不同。
- `deviceTypes`（module.json5）限定 phone/tablet/2in1 ——
  比 uses-feature 更粗的设备形态声明。
- 相机能力走 `cameraPicker` 系统组件，无需硬件特性声明。

## 四、结论

- `<queries>` 7 个 intent + 3 个 package 全归因；两个版本差
  （Singular/FB/IG@1.0.3、IMAGE_CAPTURE_SECURE@1.4.2）均与
  既有相位形成因果闭环。
- `<uses-feature>` 六条可选声明三版零差，无移植义务
  （Harmony 设备声明粒度不同）。
