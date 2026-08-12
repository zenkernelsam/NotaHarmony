# ADR-0173：系统 Backup 绑定 Bundle 版本身份

## 决策

系统快照不再写死 `1.0.0`，而是通过 `bundleManager.getBundleInfoForSelfSync()` 记录运行中
应用的 `versionName` 与 `versionCode`。恢复时把 manifest 身份与 CoreFileKit 回调提供的
`BundleVersion` 逐项绑定，并拒绝源 `versionCode` 高于当前安装版本的原始数据快照。

`bundleVersionCode` 作为 schema 1 的可选字段加入，旧 manifest 仍可依赖平台回调完成来源
版本和未来版本门禁；新 manifest 额外获得文件内代码身份校验。

## 依据

Harmony SDK 的 `BundleVersion` 契约明确：`code` 是待恢复 Bundle 的 version code，`name`
是 version name。`BundleInfo.versionCode/versionName` 则提供当前安装应用的同源身份。

## 边界

较旧快照恢复到较新应用仍由现有数据库迁移链负责；本阶段不发明跨 schema 转换协议。
系统服务实际传值、升级恢复和降级拒绝仍需设备故障注入验证。
