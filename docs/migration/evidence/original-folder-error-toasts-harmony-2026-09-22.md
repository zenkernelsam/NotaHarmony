# 原版文件夹操作专属错误提示 → HarmonyOS 移植证据（2026-09-22）

## 原版证据

- `decompiled_1.0.3/sources/defpackage/xdb.java`：移动文件夹时计算
  `iH = (beb.h(lq4VarI) - lq4VarI.getDepth()) + lq4Var.getDepth() + 1`，
  即"被移动子树最深节点的新绝对深度"；超过 6 层即抛
  `MaxFolderDepthExceededException`。
- `decompiled_1.0.3/sources/defpackage/sad.java`：创建/移动流程
  `catch (MaxFolderDepthExceededException)` → `vad.i(vadVar)` → `qad` case 1
  发送 `feature_library__error_max_folder_depth`；`catch (InvalidFolderNameException)`
  → `qad` 发送 `ui_folder__name_error_message`。
- `strings.xml`：
  - `error_max_folder_depth` = "Notability is limited to 6 levels of folders."
  - `ui_folder__name_error_message` = "A folder already exists with this name, or this
    name contains invalid characters."

## Harmony 移植

- `FolderRepositoryImpl.ets` 新增两个类型化错误：
  `MaxFolderDepthExceededError`（对应 `MaxFolderDepthExceededException`，创建路径
  `createFolder` 与移动校验 `validateFolderMove` 各一处抛出）与
  `InvalidFolderNameError`（对应 `InvalidFolderNameException`，
  `validateFolderName` 的空/斜杠非法名与同级重名两处抛出）。
- `LibraryPage.folderErrorToastRes(e, fallback)`：按 `instanceof` 映射到
  `error_max_folder_depth` / `folder_name_error`，其余错误保持原有通用文案；
  建/改文件夹提交、`moveFolder`、拖拽落点解析三个 catch 面全部接入。
- 深度上限常量 `MAX_FOLDER_DEPTH = ORIGINAL_MAX_FOLDER_DEPTH = 6` 与原版一致；
  拖拽路径经 `resolveFolderDrop → planFolderMove → validateFolderMove` 也会得到
  类型化错误，提示一致。
- 差异登记：原版经 snackbar 通道（`vad.Q`/`bxb`）呈现；Harmony 用
  `promptAction.showToast`，属平台适配差异。

## 验证

- 回放 `docs/migration/replays/d02-original-folder-error-toasts.mjs`：14 项断言
  覆盖原版 catch 派发/深度公式/字符串锚点与 Harmony 类型化抛出、三处 catch
  映射、双语资源。
- `note@default`、`note@ohosTest` 双构建通过。
