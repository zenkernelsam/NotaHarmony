# Phase 831 — application 属性面 + filepaths.xml

## 范围

三版 `<application>` 元素属性 + `res/xml/filepaths.xml`。

## 原版发现

五属性三版零差：

- `largeHeap=true`（笔记/PDF 大堆）；
- `extractNativeLibs=false`（.so 页对齐直挂）；
- `supportsRtl=true`；
- **`allowBackup=false`**（显式禁用系统备份）；
- `enableOnBackInvokedCallback=true`（预测式返回）。

`filepaths.xml`：三条 cache-path 授权——images/exports/
debug-logs（FileProvider 仅开放 cacheDir 子目录外发）。

## 重要分歧登记

原版 `allowBackup=false` 是明确产品选择（笔记数据不进
Android Auto Backup）；Harmony 已实现 `NoteBackupAbility`
系统备份（ADR-0127，2026-08-12 决策早于本审计）。
登记为**有意分歧**：保留 Harmony 实现（平台范式+用户价值），
本相位补齐原版反向证据交叉引用。

## Harmony 侧

其余属性无移植义务（Harmony 无堆声明/返回手势开关/RTL
开关）；filepaths 白名单由 share sheet URI 授权承担。

## 验证

- 新 Replay `d02-application-attrs.mjs`：**12/12**（三版
  五属性、无 networkSecurityConfig、filepaths 三授权 +
  仅 cache-path、Harmony 备份扩展存在）。
- ADR-0775。
