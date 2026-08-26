# Harmony Evidence — 页面设置共享照片导入租约

日期：2026-08-26
阶段：Phase 476
结论：通过（静态验证）

## 代码证据

- `PageSettingsPanel.ets`
  - 新增 `photoImportLeaseActive` 属性，根容器在忙碌或该租约任一存在时禁用。
  - 尺寸卡片、自定义色开关和方向按钮在原有忙碌/共享纸/间距保存门禁前拒绝该租约。
  - HSV 滑杆随根容器禁用，草稿与共享间距模型不变。
- `PageManagerBar.ets`
  - 设置按钮回调先拒绝租约再显示弹窗；弹窗 builder 在租约激活时不构建 `PageSettingsPanel`。
  - 调用点显式传入父页共享导入租约；导航、增删移动和菜单防线不变。
- 默认模板页未传新属性，保持 ArkUI 默认值 `false`，全局设置不受编辑器导入影响。

## 静态验证

- ArkTS：`PageManagerBar.ets` 无诊断；`PageSettingsPanel.ets` 无错误，仅既有未使用符号警告
  与弃用 API 信息级提示。
- 聚焦 Replay：
  `docs/migration/replays/d02-page-settings-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=7 FAILED=0`。
- 相邻 Replay：页面管理一致化 4/4、原版纸张设置、默认模板路由、页面条共享租约 10/10 通过。
- 全量 Desktop Replay：`REPLAY_FILES=417 PASSED=417 FAILED_FILES=0`
  （35.338 秒）。
- clean：3.642 秒；ohosTest HAP：11.064 秒；default HAP：33.962 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
