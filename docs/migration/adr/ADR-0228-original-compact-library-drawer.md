# ADR-0228：按原版语义补齐资料库 compact folder drawer

## 状态

已采用（2026-08-16）；设备视觉与手势验收待执行。

## 背景

原版 1.0.3 的 `ta7` 在 840dp 以下创建 DrawerState，并通过 `gsi/fq4` 递归渲染可展开的 folder
树。Harmony 旧实现只在常规宽度显示 sidebar，窄屏虽后来增加了一个动态菜单，却没有 bounded 滚动、
展开/折叠状态或与原版 row 语义相同的选中反馈。

## 决策

- compact 使用 ArkUI 原生组件组合的显式 overlay drawer：遮罩 + 左侧 bounded panel + 原生 `List`，不再
  把 folder 功能塞进无限长度的 `MenuElement[]`。
- folder 导航行统一使用 48vp 行预算；chevron 只改变 UI 展开状态，标题按钮执行选择，右侧原生
  `bindMenu` 承载低频 folder 操作。
- 当前位置由 `currentFolderId` 统一驱动；成功选择后 compact drawer 自动收起，失败时保留 drawer
  便于重试。异步 folder mutation 期间行操作禁用。
- `expandedFolderIds` 仅是 UI 状态，不写入数据库；刷新时裁剪已删除 ID，并自动展开当前 folder 的
  祖先。合法折叠子树不作为 orphan 回收。
- Phase 254 将 regular/compact 的 folder 容器统一为同一个 `List` builder，以承载原生长按拖拽；bounded
  滚动、48vp 行预算和既有导航语义保持不变。

## 原版依据

- `decompiled_1.0.3/sources/defpackage/ta7.java:58,63,104,111-116`
- `decompiled_1.0.3/sources/defpackage/fh3.java:58`
- `decompiled_1.0.3/sources/defpackage/gsi.java:612,736,1439`
- `decompiled_1.0.3/sources/defpackage/zri.java:37-40`
- `decompiled_1.0.3/sources/defpackage/vc2.java:323,340,349`

## 验证

- 专项 Node replay：`D02_ORIGINAL_COMPACT_LIBRARY_DRAWER_REPLAY_OK`。
- 全量桌面 replay：`REPLAY_FILES=236 FAILED=0`。
- `git diff --check`：通过。
- `hvigorw --no-daemon assembleHap -p product=default -p module=note@ohosTest`：`BUILD SUCCESSFUL`。
- `hvigorw --no-daemon assembleHap -p product=default -p module=note@default`：`BUILD SUCCESSFUL`。
- 未启动模拟器、虚拟机、真机或 Hypium；遮罩层触控、滑动关闭、旋转和实际字体/安全区仍待设备门。

## 后续影响

M2-U-03 的静态实现缺口已补齐，但总纲要求的三档截图仍不能标成完成。T-042 APK 版本追踪继续
严格留到整个 Goal 最后一项；完成时另写 Report，并将入口、阅读顺序和 decompile/diff 流程归纳进
Wiki、技术/API 文档和新手入门。
