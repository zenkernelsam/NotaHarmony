# Phase 831 — application 元素属性闭合 + filepaths.xml

证据：三版 `resources/AndroidManifest.xml` + `res/xml/filepaths.xml`

## 一、`<application>` 属性明细（三版全同）

| 属性 | 值 | 语义 |
|------|-----|------|
| `largeHeap` | true | 笔记渲染/PDF 大堆内存 |
| `extractNativeLibs` | false | .so 页对齐直挂（免解压） |
| `supportsRtl` | true | RTL 布局支持 |
| `allowBackup` | **false** | **原版显式禁用系统备份** |
| `enableOnBackInvokedCallback` | true | 预测式返回手势（API33+） |

未声明：`networkSecurityConfig`/`dataExtractionRules`/
`usesCleartextTraffic`/`resizeableActivity`（application 级）/
`requestLegacyExternalStorage`。

## 二、filepaths.xml（ExportFileProvider 授权路径）

```xml
<paths>
  <cache-path name="images"     path="images"/>
  <cache-path name="exports"    path="exports"/>
  <cache-path name="debug-logs" path="debug-logs"/>
</paths>
```

三条 cache-path 授权：导出图片、导出文档、调试日志——
仅 cacheDir 子目录可经 FileProvider 外发，filesDir/DB 不暴露。

## 三、备份策略分歧（重要登记）

| 面 | 原版 | Harmony |
|----|------|---------|
| 系统备份 | `allowBackup=false` 显式禁用 | `NoteBackupAbility`（BackupExtensionAbility）完整实现 |
| 依据 | — | ADR-0127（2026-08-12 平台层决策，先于本审计） |

原版禁备份是明确产品选择（笔记数据不进 Android Auto Backup，
避免跨设备/跨版本恢复产生不一致）；Harmony 侧已实现的系统备份
为**有意分歧**——ADR-0127 记为"平台 SDK 依据"，本审计补齐原版
对照：`allowBackup=false` 系原版反向证据。保留 Harmony 实现
（用户价值 + 平台范式），登记分歧不回退。

## 四、Harmony 侧其余映射

- `largeHeap`：Harmony 无堆声明等价物（JS heap 管理不同）。
- `extractNativeLibs=false`：Harmony HAP natives 安装即挂，同向。
- `supportsRtl`：ArkUI RTL 由 locale 驱动，无显式开关。
- `enableOnBackInvokedCallback`：Harmony 返回手势系统级，无开关。
- filepaths 授权面：Harmony share 走系统 share sheet + URI 权限
  自动授予，无显式路径白名单。

## 五、结论

application 属性面闭合：五声明三版零差，全部归因；filepaths.xml
三授权路径回收；`allowBackup=false` 与 Harmony 备份扩展的分歧
正式登记（ADR-0127 交叉引用）。
