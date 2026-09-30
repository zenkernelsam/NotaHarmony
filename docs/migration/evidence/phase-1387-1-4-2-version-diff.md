# Phase 1387 — 1.0.3 ↔ 1.4.2 版本差异证据

> 来源：`decompiled_1.0.3`（versionCode 1014）与 `decompiled_1.4.2`（versionCode
> 1040002，`Notability: AI Note Workspace`）。1.4.2 已用 jadx-1.5.6 反编译完成。
> 本证据为「找出 1.4.2 新增功能 / 变更 / 需同步项」的 diff 摸底（P3 前置），
> 为后续按特性逐个 Phase 移植/定 fail-closed 提供底账。

## 一、规模与版本

| 维度 | 1.0.3 | 1.4.2 | 差 |
|------|-------|-------|-----|
| Java 源（sources/） | 21,108 | 24,808 | +3,700 |
| drawable | 476 | 493 | +17（净） |
| 命名空间新增字符串 | — | — | +722 / −107 |
| versionName/Code | 1.0.3 / 1014 | 1.4.2 / 1040002 | 大版本跳跃 |

`defpackage`（混淆层）18563→21993，类名混淆，逐名 diff 无意义；
`com/gingerlabs/notability` 未混淆包 + 资源 + Manifest 是有效信号源。

## 二、新增 Manifest 组件 / 权限

- 新增 `com.gingerlabs.notability.data.handwritingrecognition.hwr.HwrEngineService`
  —— **MyScript iink 手写识别引擎服务**（云端/本地引擎混合）。
- 新增 `com.gingerlabs.notability.app.ApiGatedFirebaseInitProvider` —— Firebase 初始化门控。
- 新增权限 `android.permission.READ_CALENDAR` —— 日历事件接入。

## 三、新增未混淆包目录（feature 级信号）

`com/gingerlabs/notability/` 下新增目录：
`app/demo`、`core/common/logging`、`core/model/snapshot`、`core/workmanager`、
`data/backgroundwork`、`data/calendar/database`、`data/gallery(/outbox)`、
`data/handwritingrecognition(/hwr,/myscript)`、`data/learn/syllabus`、
`data/library/state/notelimit`、`data/loginstate`、`data/note/ops/synced`、
`data/search/engine/appsearch`、`data/settings/sync`、`data/templates(/database,/sync)`、
`data/user`、`domain/maintenance`、`feature/note/stickers/packs`、`ui/support/data`。

## 四、新增字符串命名空间（722 keys，前缀统计）

| 前缀 | 数量 | 特性 |
|------|------|------|
| `feature_library_gallery__` | 131 | **社区图库**（collections/comments/followers/publishers/discover） |
| `feature_note_stickers__` | 70 | **贴纸**（sticker packs + 菜单） |
| `feature_settings__` | 60 | 设置项新增 |
| `feature_library__` | 59 | 库功能（含 flashcard 导入） |
| `feature_note__` | 53 | 笔记功能 |
| `ui_templates__` | 47 | **模板** |
| `ui_learn__` | 45 | **Learn 学习 UI** |
| `ui_share__` | 35 | 分享 |
| `ui_tools__` | 34 | 工具（calligraphy/shape/line-style/paper） |
| `feature_learn_quiz__` | 28 | **测验**（对错/explain/AI tutor） |
| `ui_account__` | 26 | 账号 |
| `ui_text__` | 16 | 文本 |
| `ui_notecovers__` | 14 | 笔记封面 |
| `feature_paywall__` | 14 | **付费墙/订阅** |
| `ui_gallery__` | 11 | 图库 UI |
| `feature_learn_transcription__` | 10 | **音频转写** |
| `ui_planners__` | 8 | 计划本 |
| `feature_note_toolbox__` | 8 | 工具箱 |
| `feature_login__` / `feature_learn__` | 5+5 | 登录 / learn 入口 |
| `feature_note_ruler__` | 2 | 直尺（仍极少，1.0.3 即 fail-closed） |

## 五、新增 drawable（净 +17）要点

- **Shape 工具**：`ui_designsystem__shape_tool_{fill,outline,overlay,shadow}`
  + `shape_{arrow,diamond,ellipse,line,rectangle,triangle}` —— 新工具 + 6 形状库。
- **Calligraphy 笔刷样式**：`ui_tools__brushstyle_calligraphy` +
  `ui_designsystem__calligraphy_{fill,outline,overlay,shadow}` —— 第 5 种笔刷样式。
- **贴纸**：`sticker`、`stickermenu_{all,recents,your_stickers}_outline`、`your_stickers_xxlrg`。
- **图库/模板**：`gallery_{fill,outline,overlay}`、`templates_{fill,overlay}`。
- **纸样/线型**：`paper_{dotted,grid,ruled}_outline`、`line_style_{dashed,dotted,fixed,variable}`。
- **Learn/AI**：`anki_flashcards`、`quizzes_explain`、`achieve`、`dislike_audio_transcription`、
  `math`、`typestyles`、`remix`、`app_mark`。
- **登录**：`passkey`；**导入**：`file_type_csv`、`file_type_rtf`。

## 六、移植分类（P3 决策底账）

### A. 本地可移植（画布/渲染/数据，无后端依赖）
| 特性 | 说明 | 移植面 |
|------|------|--------|
| Shape 工具 | 6 形状插入/变换 | 新 ToolType + 形状元素 + 渲染 + 菜单 |
| Calligraphy 样式 | 第 5 笔刷样式 | 新 InkStyle + 渲染 + 样式字形 + 宽度档 |
| 线型（fixed/variable/dashed/dotted） | 线样式选项 | 扩展样式枚举 + 渲染 |
| 贴纸放置/移动 | 画布元素 | 贴纸元素 + 手势（包内容云端下发） |
| 本地模板 | 可复用笔记结构 | 模板实体 + 应用（云端模板市场除外） |
| CSV/RTF 导入 | 新文件类型 | 解析器 + 导入链 |
| 纸样/封面/计划本 | 已有 paper 引擎可承载 | 图标 + 模板枚举扩展 |

### B. 后端依赖（fail-closed / 需服务端或专有 SDK）
| 特性 | 依赖 |
|------|------|
| Learn 套件（flashcards/quiz/AI chat tutor/syllabus） | AI/学习后端 |
| 社区图库（collections/comments/followers） | 社交云后端 |
| 音频转写 | 转写服务 |
| Passkey 登录 / feature_login / loginstate | 账号后端 |
| MyScript HWR（HwrEngineService） | MyScript iink 专有 SDK + 服务 |
| 付费墙/订阅 | 计费后端 |
| settings sync / templates sync / gallery outbox / WorkManager | 云同步 |
| 日历（READ_CALENDAR） | 设备日历 + 账号 |

## 七、结论

1.4.2 是大版本跃进（+17% 源、+722 字符串、+1 服务、+1 权限），核心新增为
**Learn AI 学习套件、社区图库、Shape 工具、Calligraphy 笔刷、贴纸、模板**。
按项目规则：**A 类本地可移植项**进入后续 Phase 逐个实现；**B 类后端依赖项**
走既有 fail-closed 约定（ADR 记录 + 不伪造后端）。`T-042` 版本追踪仍为 Goal 末项，
本 diff 是其直接输入之一。
