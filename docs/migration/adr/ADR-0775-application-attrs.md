# ADR-0775 — application 属性面闭合 + 备份分歧登记

- 状态：已接受
- 证据：`docs/migration/evidence/phase-831-application-attrs.md`
- 回放：`docs/migration/replays/d02-application-attrs.mjs`（12/12）

## 原版面（三版全同）

`largeHeap=true` / `extractNativeLibs=false` / `supportsRtl=true` /
`allowBackup=false` / `enableOnBackInvokedCallback=true`；无
networkSecurityConfig。`filepaths.xml` 三条 cache-path 授权
（images/exports/debug-logs）。

## 决定

1. **备份分歧正式登记**：原版 `allowBackup=false`（笔记数据
   不进系统备份，规避跨版本恢复不一致）；Harmony 已实现
   `NoteBackupAbility` 系统备份（ADR-0127，先于本审计）。
   保留 Harmony 实现不回退——平台范式 + 用户价值；本 ADR
   补齐原版反向证据并交叉引用。
2. `largeHeap`/`extractNativeLibs`/`supportsRtl`/
   `enableOnBackInvokedCallback` 为 Android 特有声明，无
   Harmony 等价义务，归档不移植。
3. filepaths 白名单模型不移植——Harmony share 走系统
   share sheet + URI 自动授权。

## 后果

manifest `<application>` 属性层闭合；备份分歧成为正式登记项。
