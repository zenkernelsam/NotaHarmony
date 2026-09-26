# ADR-0774 — `<queries>`/`<uses-feature>` 明细归档

- 状态：已接受（Android 特有声明，无 Harmony 移植义务）
- 证据：`docs/migration/evidence/phase-830-queries-features.md`
- 回放：`docs/migration/replays/d02-queries-features.mjs`（12/12）

## 决定

1. `<queries>` 为 Android 11+ 包可见性机制；Harmony
   `bundleManager.canOpenLink`/显式 want 模型不同——**不移植**，
   仅归档明细与版本差。
2. `<uses-feature>` 六条全部 `required=false`（商店不限制）；
   Harmony 设备形态由 `deviceTypes` 声明——**不移植**，登记为
   平台声明粒度差异。
3. 版本差归因闭环：
   - `READ_PERMISSION_SINGULAR` + katana/instagram @1.0.3 →
     Phase 817 Singular/社交分享链路；
   - `IMAGE_CAPTURE_SECURE` @1.4.2 → Phase 826 锁屏拍照链路
     （showWhenLocked/turnScreenOn 配套可见性声明）。

## 后果

manifest 元素层（application/activity/service/receiver/provider/
queries/uses-feature/meta-data/permission）全部闭合。
