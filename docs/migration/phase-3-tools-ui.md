# Phase 3 — 工具系统与交互 UI

> 版本: v1.0 | 日期: 2026-08-02 | 状态: 待工人执行
> 前置: Phase 2 渲染与输入核心通过审核（T-008~T-015）

---

## 1. 阶段目标

实现完整的工具系统和交互 UI，使核心交互流可走通：
**新建笔记 → 多工具书写 → 选区变换 → 多页管理 → 返回资料库**

包含：
- 双层导航（LibraryPage → NotePage，主栈 + 笔记内部栈分离）
- 资料库 UI（文件夹/笔记列表/网格 + 600/840/952/1400vp 响应式断点）
- 数据持久化（relationalStore 实现 Phase 1 定义的 Repository 接口）
- 完整工具栏（Pen/Pencil/Highlighter/Eraser/Selection + 颜色/粗细面板）
- 多页管理（增删/排序/尺寸/纸张模板程序化绘制）
- Undo/Redo（基于 op 栈）
- 选区工具（矩形 + 套索 + 移动/旋转/缩放/删除）
- 形状工具（笔画完成 → 直线/椭圆/多边形识别替换）
- 文本框（创建/编辑/统一变换）

**完成标准**：在模拟器上可演示完整交互流（创建→书写→切换工具→选区→多页→返回库→重新打开）。

---

## 2. 架构设计

### 2.1 页面结构（§39 移植）

```
AppRoot (NoteAbility)
└── MainNavigation (router)
    ├── Index.ets              入口（重定向到 Library）
    ├── LibraryPage.ets        资料库（主栈第一层）
    │   ├── Sidebar            左侧导航（Home/Notes/Folders）
    │   └── LibraryContent     笔记网格/列表
    └── NotePage.ets           笔记编辑器（主栈第二层）
        ├── EditorToolbar      顶部工具栏
        ├── ToolRail           右侧工具轨（Phase 3 简化为工具栏内）
        ├── NoteCanvas         画布（复用 Phase 2 NoteCanvasPage 核心逻辑）
        └── PageManager        底部页面管理条
```

### 2.2 数据层

```
data/
├── DatabaseHelper.ets         DDL 常量（Phase 1 已有）
├── DatabaseManager.ets        relationalStore 初始化 + 迁移（T-017）
├── NoteRepositoryImpl.ets     NoteRepository 实现（T-017）
├── PageRepositoryImpl.ets     PageRepository 实现（T-017）
├── ToolRepositoryImpl.ets     ToolRepository 实现（T-017）
└── AssetRepositoryImpl.ets    AssetRepository 实现（T-017）
```

### 2.3 状态管理

```
ui/
├── library/
│   ├── LibraryPage.ets        @Entry 页面
│   └── LibraryViewModel.ets   笔记列表状态（@Observed）
├── editor/
│   ├── NotePage.ets           @Entry 页面
│   ├── EditorViewModel.ets    编辑器状态（当前工具/颜色/宽度/页面列表）
│   ├── EditorToolbar.ets      工具栏组件
│   ├── PageManagerBar.ets     页面管理条
│   └── NoteCanvasView.ets     画布组件（从 NoteCanvasPage 重构为可嵌入组件）
├── components/
│   ├── ColorPicker.ets        颜色选择器
│   ├── WidthSlider.ets        粗细选择器
│   └── SelectionOverlay.ets   选区边框/控制点
└── theme/
    └── EditorTheme.ets        主题 token（颜色/间距/圆角）
```

---

## 3. 响应式布局规格（§39.4）

| 屏宽 (vp) | 侧栏 | 笔记列数 | 行为 |
|-----------|------|----------|------|
| < 600 | 隐藏 | 2 | 抽屉式侧栏 |
| 600~839 | 隐藏 | 3 | 抽屉式侧栏 |
| 840~951 | 280vp 常驻 | 2 | 固定侧栏 |
| 952~1399 | 332vp 常驻 | 3 | 固定侧栏 |
| ≥ 1400 | 332vp 常驻 | 4 | 固定侧栏 |

实现：使用 ArkUI `mediaquery` 或 `onAreaChange` 监听宽度，动态切换布局。

---

## 4. 核心交互规格

### 4.1 工具栏（§22/§39.6）

| 工具 | 图标 | 行为 |
|------|------|------|
| Pen | 钢笔 | MONO/TAPER 切换，颜色/宽度面板 |
| Pencil | 铅笔 | PencilSplat 渲染，压感/倾斜响应 |
| Highlighter | 荧光笔 | 半透明 (alpha=0.42)，固定宽度 |
| Eraser | 橡皮擦 | PARTIAL/WHOLE 切换 |
| Selection | 套索 | 矩形/自由套索切换 |

工具栏高度 48vp，单工具点击区 48vp，图标 24vp。

### 4.2 选区操作（§25 精简版）

Phase 3 实现的选区菜单（从 22 项精简为核心 8 项）：
- COPY / CUT / DELETE
- SEND_FORWARD / SEND_BACKWARD
- FLIP_HORIZONTALLY / FLIP_VERTICALLY
- DESELECT

变换操作：
- 移动：拖拽选区 → 修改 transform 矩阵平移
- 缩放：双指/控制点 → 修改 transform 矩阵缩放
- 旋转：旋转手柄 → 修改 transform 矩阵旋转

### 4.3 形状识别（§24）

触发：笔画完成时（非实时），shapeDetectionEnabled=true 时自动执行。
支持：直线 / 椭圆 / 多边形。
失败：保留原始手画路径。

### 4.4 Undo/Redo

基于 op 栈：
- undoStack: Op[]（最多 50 步）
- redoStack: Op[]
- 每次笔画完成/擦除/变换 → push op
- Undo → pop undoStack, push redoStack, 反向执行
- Redo → pop redoStack, push undoStack, 正向执行

### 4.5 纸张模板程序化绘制（§7）

| 模板 | 绘制方式 |
|------|----------|
| PLAIN | 空白 |
| LINES | 横线，间距 28vp，线宽 1px |
| GRID | 水平+垂直，间距 28vp |
| DOTS | 点阵，间距 28vp，半径 1.25px |

---

## 5. 涉及鸿蒙 API

| API | 起始版本 | 用途 |
|-----|----------|------|
| @ohos.data.relationalStore | 9 | 数据持久化 |
| @ohos.router | 7 | 页面导航 |
| @ohos.mediaquery | 10 | 响应式断点（可选，也可用 onAreaChange） |
| Canvas + OffscreenCanvas | 8/9 | 纸张模板/画布（Phase 2 已用） |

---

## 6. 任务卡拆分

| 卡号 | 名称 | 依赖 | 产出 |
|------|------|------|------|
| T-016 | 应用壳与双层导航 | Phase 2 | Index 重定向 + LibraryPage 空壳 + NotePage 空壳 + 路由 |
| T-017 | 数据层实现 | T-016 | DatabaseManager + 4 个 RepositoryImpl |
| T-018 | 资料库 UI | T-017 | 侧栏 + 笔记网格 + 响应式断点 + 新建/删除 |
| T-019 | 编辑器工具栏 | T-016 | EditorToolbar + 颜色/宽度面板 + 工具切换状态 |
| T-020 | 多页管理与纸张模板 | T-017, T-019 | PageManagerBar + PaperRenderer + 页面增删 |
| T-021 | Undo/Redo | T-019 | UndoRedoManager + 工具栏按钮 |
| T-022 | 选区与变换 | T-019, T-021 | SelectionTool + 变换矩阵 + 选区菜单 |
| T-023 | 形状识别 | T-009 | ShapeDetector + 笔画完成触发 |
| T-024 | 文本框 | T-022 | TextBlockTool + 编辑态 + 渲染 |
| T-025 | 集成联调 | T-016~T-024 | 完整交互流验证 + 修复 |

### 依赖图

```
T-016 (导航壳) ─┬→ T-017 (数据层) ─┬→ T-018 (资料库)
                │                    └→ T-020 (多页)
                └→ T-019 (工具栏) ─┬→ T-021 (Undo) ─→ T-022 (选区) ─→ T-024 (文本)
                                   └→ T-023 (形状，仅依赖 T-009)
全部 ──────────────────────────────────────────────────→ T-025 (集成)
```

**建议执行顺序**：T-016 → T-017 → T-018/T-019（可并行）→ T-020/T-021 → T-022/T-023 → T-024 → T-025

---

## 7. 验收基准（模拟器阶段）

| 项 | 标准 | 验证方式 |
|----|------|----------|
| 导航 | Index → Library → Note → 返回 Library | 模拟器操作 |
| 资料库 | 新建/删除笔记，网格显示 | UI 树验证 |
| 响应式 | 窗口缩放时列数变化 | 模拟器调整窗口 |
| 工具切换 | Pen/Pencil/Highlighter/Eraser/Selection 可切换 | 手动测试 |
| 多页 | 添加/删除页面，翻页 | 手动测试 |
| Undo/Redo | 画一笔→Undo→消失→Redo→恢复 | 手动测试 |
| 选区 | 框选→移动→删除 | 手动测试 |
| 形状 | 画圆停笔→变椭圆 | 手动测试 |
| 文本 | 双击→文本框→输入→完成 | 手动测试 |
| 持久化 | 写笔画→退出→重新打开→笔画还在 | 手动测试 |
| 无崩溃 | 全流程操作 60 秒无异常 | hilog |

---

## 8. 约束提醒

- 响应式布局用 vp，不硬编码像素。
- 资料库断点 600/840/952/1400vp 必须实现（§39.4 已闭环的规则）。
- 主导航和笔记内部导航分离（router 栈管理）。
- relationalStore 实现必须覆盖 Phase 1 DDL 的全部 6 张表。
- 选区变换修改的是 transform 矩阵（不修改原始点数据）。
- 形状识别使用 Phase 2 的 RecognitionProvider 接口（但 Phase 3 自己实现一个简单版本）。
- 文本框 MVP 只支持纯文本，富文本后续扩展。
