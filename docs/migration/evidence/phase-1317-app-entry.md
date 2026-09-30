# Phase 1317 证据 — Harmony 应用入口 + Want 分流

来源：`noteability/NoteAbility.ets`、`noteformability/`、
`noteformeditability/`、`pages/Index.ets`。

## `NoteAbility extends UIAbility`（≈ MainActivity+App）

```
onCreate(want, launchParam):
  enqueueSharedWantUris(want)   — 分享导入
  enqueueLaunchAction(want)     — 快捷方式动作（v50）
  enqueueDeepLinkWant(want)     — 深链
  enqueueOpenTargetWant(want)   — 打开目标（URI）
  ThemeStore.init()
onNewWant                       — 热启动同样入队
onWindowStageCreate:
  restoreThemeAndLoadContent()  — 主题恢复+loadContent
    catch → loadMainContent（主题失败降级）
  loadContent('pages/Index')
```

→ **Want 分流队列**（分享/快捷/深链/打开目标入队，
`LibraryPage` 显示时消费）—— 对照原版 MainActivity
intent 处理（`ConcurrentLinkedQueue X` 队列）。

## 4 Ability + 卡片编辑

```
NoteAbility           主入口 ≈ MainActivity
NoteBackupAbility     备份 ≈ 备份 service
NoteFormAbility       Form 卡片 ≈ AppWidgetProvider
  pages/{FolderNotesCard,NewNoteCard,NewRecordingCard,
         FolderNotesEditPage}
NoteFormEditAbility → noteformeditability/
  {FolderFormEditAbility,NoteThumbnailFormEditAbility}
                       ≈ 卡片配置 Activity
pages/Index           根 struct
```

## 语义

应用入口 = `UIAbility` + Want 分流队列（分享/快捷/
深链/打开目标）+ 主题初始化+降级 + 4 Ability（主/
备份/卡片/卡片编辑）—— 对照原版壳语义保真。

## Harmony 决策

`MainActivity` intent/Startup → `UIAbility` onCreate+
Want 队列+onWindowStageCreate；widget→`FormAbility`；
配置→`FormEditAbility` —— 入口架构语义映射。

## 产出

- fixture `d02-app-entry.mjs`（10 断言）。
- ADR-1261；中文报告。
