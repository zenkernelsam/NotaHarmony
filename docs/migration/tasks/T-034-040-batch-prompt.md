# T-034~T-040 合并派工 Prompt（最终打磨批次）

> 用途：直接复制下方内容作为工人 Agent 的首条消息。可一次性派给一个工人顺序执行，或拆给多个工人并行（注意并行冲突提示）。

---

## 你的角色

代码工人。按任务卡精确实现，遇到任务卡未覆盖的决策停下来问，不擅自改契约。

## 工作区

`C:\HarmonyProject\NotaHarmony`

## 任务批次（按顺序执行）

| 顺序 | 任务卡 | 内容 |
|------|--------|------|
| 1 | `docs/migration/tasks/T-034-canvas-zoom-pan.md` | 画布缩放与平移（P0 核心） |
| 2 | `docs/migration/tasks/T-035-library-enhance.md` | 缩略图 + 搜索 + 排序 |
| 3 | `docs/migration/tasks/T-036-editor-polish.md` | 标题编辑 + Undo 全覆盖 |
| 4 | `docs/migration/tasks/T-037-page-settings.md` | 纸张尺寸/模板选择器 |
| 5 | `docs/migration/tasks/T-038-dark-mode.md` | 暗色模式 |
| 6 | `docs/migration/tasks/T-039-folders.md` | 文件夹管理 |
| 7 | `docs/migration/tasks/T-040-final-regression.md` | 最终集成回归（17 步） |

**每张卡做完立即验证（check_ets_files + build_project）再做下一张。**

## 开工前必读

1. 当前要做的任务卡（按上表顺序）
2. `docs/migration/00-OVERVIEW.md` — 全局约束
3. 相关已有代码（任务卡内指明）

## 全局规则

- **不修改 Phase 1 契约文件**（`core/model/` 和 `core/adaptation/` 下的接口定义）
- **不修改 docs/migration/ 架构文档**
- **UI 交互类控件用 ArkUI 原生组件**（bindMenu/AlertDialog/bindPopup/Slider），自绘仅限无原生等价物的展示类
- 尺寸用 vp，颜色走 theme tokens（T-038 后）
- 每张卡写完成报告到 `docs/migration/reports/T-0NN-完成.md`

## 并行提示（如果拆给多个工人）

- T-034（rendering/ui）与 T-035（library）可并行
- T-038（主题）会触碰所有页面，建议单独做或最后做
- T-039（文件夹）触碰 LibraryPage 和数据库，与 T-035 有文件冲突，建议顺序做
- **T-040 必须最后做**（依赖前面全部完成）

## 每卡提交

```
git add note/src/main/ets/ docs/migration/reports/
git commit -m "impl(T-0NN): <内容>"
```

## 最终验收（T-040）

17 步回归清单全部通过 + 连续操作 2 分钟无崩溃。

---

## 遗留事项（不在本批次，真机阶段处理）

- 压感曲线真机调参（模拟器无真实压感）
- 延迟 P50/P95 量测
- PencilSplat ellipseR 钳制的真机复验（orientation 数据可用后）
- WebDAV 真实服务器连接测试
- T-032（强工人）.note 格式解析整合
