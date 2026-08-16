# Phase 251 修复总结：原版资料库 compact 文件夹抽屉

## 目标

承接 M2-U-03：严格对照 Notability 1.0.3 的 `ta7/gsi/fq4/vc2/zri`，修复手机宽度下 folder
入口不可达、层级状态缺失和长列表溢出问题。保持现有 FolderRepository 的 parent/sibling/order、
名称校验和异步 mutation 语义不变。

## 已完成

- `LibraryPage.ets` 新增 compact drawer 状态、遮罩/关闭、当前位置入口和 44vp 汉堡 hit target。
- drawer 与 regular sidebar 均使用 bounded vertical 容器；本阶段最初为 `Scroll`，后续 Phase 254 为承载
  原生拖拽统一替换成共享 `List`。folder 行仍统一 48vp，支持全部笔记、
  选中勾选、chevron 展开/折叠、递归层级和原生操作菜单。
- 新建、重命名、删除、移动仍复用已有 repository 与确认对话框；folderBusy 时禁用重复入口，选择
  成功后收起 compact drawer，失败保留当前上下文。
- 补审修正了选择行原先“调用异步 `selectFolder()` 后立即收起 drawer”的竞态；现在收起动作只发生在
  `setFolder`、刷新列表和缩略图均成功后，读取/渲染失败时抽屉保持打开，用户可以直接重试。
- 刷新/删除后清理失效展开 ID，自动展开当前位置祖先；边修边审发现并修复“折叠子树被 orphan fallback
  重新显示”的树遍历 bug。
- 增加中英文 `folders/open_folder_drawer/close/expand_folder/collapse_folder` 资源。
- 新增 `ADR-0228`、原版 evidence 和 `d02-original-compact-library-drawer.mjs` 专项回放。

## 原版对照

原版 `ta7.java:58,63` 明确在 `<840dp` 建立 DrawerState，不是永久隐藏 sidebar；`gsi.java` 通过
`fq4.l()` 控制递归子树；`zri/vc2` 提供 Folders、Add、Rename、Delete 入口。Harmony 的 overlay 是
ArkUI 适配决策，280--320vp drawer 宽度和 44vp compact 入口是移植侧布局预算，不能标成原版常量。

## 验证

- 专项：`D02_ORIGINAL_COMPACT_LIBRARY_DRAWER_REPLAY_OK drawer-state=1|folder-scroll=1|tree-expand-collapse=1|selection-check=1|folder-actions=1|compact-hit-targets=1|original-thresholds=1`。
- 全量桌面回放：`REPLAY_FILES=236 FAILED=0`。
- `git diff --check`：通过。
- 两个 HAP target 均 `BUILD SUCCESSFUL`：`note@ohosTest`、`note@default`。
- 异步关闭竞态修正后再次执行专项 replay、`git diff --check`，并串行重建两个 target，结果仍通过。
- 没有启动虚拟机/模拟器/真机，也没有执行 Hypium；三档截图、抽屉动画/滑动手势、字体度量和真实
  触控仍是明早设备验收项，不能据此宣称 M2-U-03 的设备门已关闭。

## Goal 纪律

T-042 APK 版本追踪仍按约定留到整个 Goal 最后。本阶段只记录它的延期约束；最终创建追踪文档时，
必须另写中文 Report，说明创建内容、解决的问题、入口和使用方式，并把入口/阅读顺序/decompile-diff
流程归纳进 Wiki、技术/API 文档与新手入门。
