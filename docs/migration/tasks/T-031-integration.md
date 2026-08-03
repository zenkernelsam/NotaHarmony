# T-031 集成联调

## 目标

将 T-026~T-030 集成为完整可用的备份/导入导出/WebDAV 流程，修复集成问题，验证端到端功能。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §7（验收基准）
- 依赖：T-026~T-030 全部产出

## 实现要求

### 集成验证清单

在模拟器上逐步执行：

```
本地导入导出：
1. 创建一个有笔画的笔记
2. BackupPage → "导出当前笔记" → 选择保存位置 → 文件生成
3. 删除该笔记
4. BackupPage → "从 .note 导入" → 选择刚导出的文件
5. 验证：笔记恢复，笔画/页面/标题完整

WebDAV（需要测试服务器）：
6. WebDAVSettingsPage → 填入服务器/凭证 → "测试连接" → 成功提示
7. BackupPage → "备份全部笔记" → 上传完成
8. 删除本地全部笔记
9. BackupPage → "从云端恢复" → 列表显示 → 选择 → 下载导入
10. 验证：笔记恢复

异常处理：
11. 导入一个损坏文件 → 友好错误提示，不崩溃
12. WebDAV 填错密码 → 401 错误提示
13. 网络断开时备份 → 超时错误提示
```

### 修复工作

- 确保 BackupPage 正确调用 NoteExporter/NoteImporter/WebDAVClient
- 确保页面路由正确注册
- 确保 Preferences 配置读写正确
- 确保异步操作不阻塞 UI（loading 状态）
- 修复任何类型不匹配/import 路径错误

### 鸿蒙特有约束

- 不新建大型架构文件（集成卡只修复和连接）
- WebDAV 测试如果没有可用服务器，标注"待用户提供测试服务器"
- 本地导入导出必须完整验证（不依赖外部服务）

## 验收标准

- [ ] `check_ets_files` 全部文件零错误
- [ ] `build_project` BUILD SUCCESSFUL
- [ ] `start_app` 运行成功
- [ ] 本地导出→删除→导入→恢复 全流程通过
- [ ] 导入损坏文件不崩溃
- [ ] WebDAV 配置页面可保存/读取
- [ ] hilog 无应用级 ERROR
- [ ] 不修改 Phase 1 契约文件

## 完成报告

`docs/migration/reports/T-031-完成.md`（记录修复的集成问题 + WebDAV 测试状态）
