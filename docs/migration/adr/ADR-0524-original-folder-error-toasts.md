# ADR-0524: 原版文件夹操作专属错误提示

日期：2026-09-22（Phase 553）

## 背景

原版 `sad.java` 对文件夹创建/移动失败做分类派发：深度超限
（`MaxFolderDepthExceededException`）与非法名称
（`InvalidFolderNameException`）各有专属文案，经 snackbar 通道提示；
其余错误不吞掉但也不误导用户。Harmony 先前对两类失败只弹通用
`folder_operation_failed` / `move_folder_failed`，丢失原版的可读错误语义。

## 决策

1. `FolderRepositoryImpl` 新增 `MaxFolderDepthExceededError`、
   `InvalidFolderNameError` 两个 `Error` 子类，替换原有匿名 `Error`：
   - 深度： `createFolder`（父深度已达 6 层）与 `validateFolderMove`
     （父深度 + 子树高 > 6）各一处；
   - 名称： `validateFolderName` 的空/斜杠非法名与同级重名各一处。
2. `LibraryPage` 新增 `folderErrorToastRes(e, fallback)` 统一映射，三个
   catch 面（对话框提交、移动、拖拽落点解析）共用，保持生命周期守卫不变。
3. 其余结构性错误（目标不存在、移入自身子树等）继续走原有通用文案——原版
   对这些路径同样没有专属字符串。

## 理由

- 类型化错误忠实对应原版的异常类型与文案分流，且无需在错误字符串里做
  文本匹配。
- 拖拽路径复用 `planFolderMove` 校验，错误类型自然穿透到同一映射。

## 备选

- 在 UI 层先做深度预检再拦截：会与仓储校验重复且易漂移，弃用。
- 字符串消息匹配：`message` 属实现细节，不可靠，弃用。
