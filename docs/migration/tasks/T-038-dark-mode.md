# T-038 暗色模式

## 目标

实现 Light/Dark 主题：跟随系统 + 手动切换，全部页面和画布适配。

## 实现要求

### 1. 主题 token

创建 `note/src/main/ets/ui/theme/EditorTheme.ets`：

```typescript
export interface ThemeTokens {
  background: string;      // 页面背景
  surface: string;         // 卡片/工具栏背景
  textPrimary: string;
  textSecondary: string;
  paperBackground: string; // 画布纸张底色
  paperLineColor: string;  // 纸张线/点颜色
  accent: string;          // 选中高亮
}
export const LightTheme: ThemeTokens = { ... }
export const DarkTheme: ThemeTokens = { ... }
```

推荐色值：Light 纸张 #FFFFFF、线 #E0E0E0；Dark 背景 #1A1A1A、纸张 #262626、线 #3A3A3A。

### 2. 主题状态管理

创建 `ThemeStore`（AppStorage 存 'themeMode': 'system'|'light'|'dark'）：
- system：跟随 ConfigurationConstant.ColorMode
- 监听系统颜色变化自动切换

### 3. 全页面适配

- LibraryPage / NotePage / BackupPage / WebDAVSettings：背景/文字/卡片色绑定 theme tokens
- EditorToolbar / PageManagerBar：surface 色
- PaperRenderer：纸张底色/线色从 tokens 读取
- 画布笔画颜色不受影响（用户选的笔色保持不变）
- 设置入口（LibraryPage 或 BackupPage 内）：主题切换 bindMenu（跟随系统/浅色/深色）

### 约束

- 用 @StorageLink/@StorageProp 绑定主题状态，切换即时生效
- 不硬编码颜色到组件里（全部走 tokens）

## 验收标准

- [ ] 手动切换深色 → 全部页面变暗色，画布纸张变深
- [ ] 跟随系统模式时，系统切暗色应用同步变化
- [ ] 主题选择持久化（重启保留）
- [ ] 深色下笔画/工具栏/菜单可读性正常
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-038-完成.md`
