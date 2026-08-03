# T-030 备份 UI 与设置

## 目标

实现备份/恢复/导入导出 UI 页面 + WebDAV 配置页面 + Preferences 配置存储。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §3.2（同步策略）、§3.3（设置存储）
- 依赖：T-027（导出）、T-028（导入）、T-029（WebDAV）
- 鸿蒙 API：@ohos.data.preferences

## 实现要求

### 创建文件

1. `note/src/main/ets/ui/settings/BackupPage.ets`（@Entry 页面）
2. `note/src/main/ets/ui/settings/WebDAVSettingsPage.ets`（@Entry 页面）
3. 修改 `note/src/main/resources/base/profile/main_pages.json`（注册新页面）
4. 修改 `note/src/main/ets/ui/library/LibraryPage.ets`（添加"设置"入口按钮）

### BackupPage 布局

```
Column {
  Text("备份与同步").fontSize(24)

  // 本地导入导出区
  Section("本地文件") {
    Button("导出当前笔记为 .note")
    Button("从 .note 文件导入")
  }

  // WebDAV 区
  Section("WebDAV 云备份") {
    Text("服务器: " + config.serverUrl || "未配置")
    Button("配置 WebDAV")  → 跳转 WebDAVSettingsPage
    Button("备份全部笔记到云端")  // 需要已配置
    Button("从云端恢复")         // 需要已配置
    Text("上次备份: " + lastBackupTime)
  }
}
```

### WebDAVSettingsPage 布局

```
Column {
  TextInput("服务器 URL").placeholder("https://dav.example.com")
  TextInput("用户名")
  TextInput("密码").type(InputType.Password)
  TextInput("备份路径").placeholder("/nota-backup/")

  Button("测试连接")  → 显示结果
  Button("保存配置")  → 写入 Preferences
}
```

### 配置存储（Preferences）

```typescript
// key 值
const PREF_KEY_SERVER_URL = 'webdav_server_url';
const PREF_KEY_USERNAME = 'webdav_username';
const PREF_KEY_PASSWORD = 'webdav_password';
const PREF_KEY_BACKUP_PATH = 'webdav_backup_path';
const PREF_KEY_LAST_BACKUP = 'webdav_last_backup';
```

### 交互流程

- "备份全部笔记"：exportAllNotes() → 逐个 upload() → 更新 lastBackupTime → Toast 成功
- "从云端恢复"：listDir() → 展示列表 → 用户选择 → download() → importFromData() → Toast
- 操作中显示 loading 状态（Progress 组件）
- 错误用 AlertDialog 展示

### 鸿蒙特有约束

- Preferences 用 `import { preferences } from '@kit.ArkData'`
- 密码 MVP 明文存储（后续可加密）
- 备份/恢复是异步操作，用 @State isLoading 控制 UI
- 页面路由注册到 main_pages.json

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] LibraryPage 有入口可进入 BackupPage
- [ ] BackupPage 导出/导入按钮功能正常
- [ ] WebDAVSettingsPage 可保存配置
- [ ] 配置持久化（重启后仍在）
- [ ] 未配置 WebDAV 时备份按钮禁用
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-030-完成.md`
