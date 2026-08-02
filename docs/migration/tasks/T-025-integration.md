# T-025 集成联调

## 目标

将 T-016~T-024 的全部模块集成为可走通的完整交互流，修复集成问题，确保全流程无崩溃。

## 参考

- 契约：`docs/migration/phase-3-tools-ui.md` §7 验收基准
- 依赖：T-016~T-024 全部产出

## 实现要求

### 修改文件（集成修复，不新建大文件）

主要工作：
1. 确保 NotePage 正确组装：EditorToolbar + NoteCanvasView + PageManagerBar
2. 确保 LibraryPage → NotePage 传参（noteId）→ 加载对应笔记数据
3. 确保笔画/文本/形状持久化到 relationalStore（通过 OpRepository 或简化为直接存）
4. 确保退出编辑器 → 返回资料库 → 重新打开笔记 → 内容恢复
5. 修复各模块间的类型不匹配、import 路径错误、状态同步问题

### 完整交互流验证清单

在模拟器上逐步执行：

```
1. 启动 → 自动进入 LibraryPage
2. 点击 FAB "+" → 创建新笔记 → 进入 NotePage
3. Pen 工具画几笔 → 可见平滑笔迹
4. 切换 Pencil → 画几笔 → 可见纹理效果
5. 切换 Highlighter → 画几笔 → 半透明效果
6. 切换 Eraser → 擦除部分笔画
7. Undo → 恢复擦除的内容
8. 切换 Selection → 框选笔画 → 移动 → 删除
9. 画一个近似圆 → 自动识别为椭圆
10. 双击空白 → 文本框 → 输入文字 → 完成
11. 添加新页面 → 翻页 → 在第 2 页画几笔
12. 点击 Back → 返回 LibraryPage
13. 点击刚创建的笔记 → 重新进入 → 内容还在
14. 长按笔记 → 删除 → 笔记消失
```

### 持久化策略（MVP 简化）

Phase 3 的持久化不需要完整 op 流序列化。简化方案：
- 笔画完成时 → 将 StrokeElementData 序列化为 JSON → 存入 client_op 表（payload = JSON bytes）
- 打开笔记时 → 从 client_op 读取全部 → 反序列化 → 重建 completedStrokes
- 页面信息 → page_info 表
- 笔记元数据 → note_meta 表

### 鸿蒙特有约束

- 不新建大型架构文件（这是集成卡，只修复和连接）。
- 序列化用 `JSON.stringify` / `JSON.parse`（Uint8Array 用 TextEncoder/TextDecoder）。
- 如果某个前序任务卡的产出有 bug，在本卡中修复并记录。
- 全流程操作 60 秒内无崩溃、无 hilog ERROR（应用级）。

## 验收标准

- [ ] `check_ets_files` 全部文件零错误
- [ ] `build_project` BUILD SUCCESSFUL
- [ ] `start_app` 运行成功
- [ ] 上述 14 步交互流全部走通
- [ ] 退出重进笔记内容恢复（持久化有效）
- [ ] hilog 无应用级 ERROR
- [ ] 不修改 Phase 1 契约文件

## 完成报告

`docs/migration/reports/T-025-完成.md`（记录修复了哪些集成问题）
