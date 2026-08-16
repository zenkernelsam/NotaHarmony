# ADR-0231：文件夹拖拽保持原版 parentId + childIndex 契约

## 状态

已采用（2026-08-16）；ArkUI 插入线、自动滚动和真实触控手感待设备验收。

## 背景

原版 1.0.3 的拖拽结果不是“移动到某父级并永远追加”，而是
`DragFolderResult(folderId, parentId, childIndex)`。`xdb` 根据目标父级的 child index，在首项前、末项后或
相邻项之间计算 position。Harmony 侧已有 parent/siblingOrder 和移动校验，但旧接口只接收 parentId，资料库也没有
原生拖拽入口，无法表达同级任意位置重排。

## 决策

- 仓储移动契约扩展为 `moveFolder(folderId, parentId, insertIndex?)`；纯逻辑 `planFolderMove()` 先产生旧父级与
  新父级的完整兄弟序列，再在同一事务写回连续 child index。
- 不照搬原版 fractional position。Harmony 本地表把等价顺序保存为连续 `0..n-1`，避免长期平均值插入造成精度和
  重复 position；对外语义仍是原版 `parentId + childIndex`。
- regular sidebar 与 compact drawer 共用原生 `List`。拖拽开始时固定可见 ID、深度、源 index 和横向锚点；回调期间
  即使 UI 状态变化，也不重新用当前列表猜源对象；回调必须返回 `FolderDragPreview` builder，满足 ArkUI 起拖节点
  契约。
- OpenHarmony 6.0 Release 引擎会从 source 仍存在的 `itemPosition_` 计算 `onItemDrop.insertIndex`。因此
  `resolveFolderDrop()` 把回调值视为移除前边界，并扣除边界前的 source 可见子树；这保证同列表向下移动不偏一位。
- 按原版 `gsi/im3` 的 48dp 行高与 24dp 层级步进恢复横向深度语义。ArkUI 提供纵向 insert boundary，横向位移决定
  requested depth；没有横向层级意图时保持原深度，向右可进入空父级或已有父级，向左可退出层级。
- 拖动 folder 时整棵可见子树从边界计算中移除，后代不能成为自身落点锚点；最终仍通过自身子树、同级重名和六层上限
  校验。
- 菜单保留“上移/下移”和显式“移动到文件夹”，作为键盘、无障碍以及设备拖拽失败时的后备路径。

## 原版依据

- `decompiled_1.0.3/sources/defpackage/cm3.java:9-13,54-58`
- `decompiled_1.0.3/sources/defpackage/id7.java:170-172`
- `decompiled_1.0.3/sources/defpackage/sad.java:94-106`
- `decompiled_1.0.3/sources/defpackage/xdb.java:87-109,124-144`
- `decompiled_1.0.3/sources/defpackage/gsi.java:962-978`
- `decompiled_1.0.3/sources/defpackage/im3.java:132-198,213-220`
- APK `classes2.dex` 的 raw `dm3.invoke()`：横坐标按 24dp 取目标 depth，纵向候选使用 48dp 行预算及
  25%/75% 区间生成 before/inside/after 结果。
- OpenHarmony `arkui_ace_engine` `OpenHarmony-6.0-Release`
  `5d55560ccaec9f4df291f7d894aef914b7873297`：`list_pattern.cpp:2863-2894`、
  `list_event_hub.cpp:88-99,167-183`、`js_list.cpp:747-779`、
  `drag_drop_manager.cpp:1895-1899,1961-1972`。

## 验证

- `d02-original-folder-indexed-drag.mjs`：
  `D02_ORIGINAL_FOLDER_INDEXED_DRAG_REPLAY_OK parent-child-index=1|before-middle-after=1|arkui-pre-removal-boundary=1|subtree-unit=1|horizontal-depth-24dp=1|drag-preview-builder=1|empty-parent=1|contiguous-transaction=1|fallback-actions=1`。
- `FolderRepository.test.ets` 覆盖首项、中间、末项、跨父级、整棵子树、无横向意图、横向入层和空父级。
- 全量桌面 replay：`REPLAY_FILES=240 FAILED=0`。
- `note@ohosTest` 与 `note@default` 均 `BUILD SUCCESSFUL`；`git diff --check` 通过。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 后续影响

原版 child-index 数据契约、可起拖 preview builder 和静态拖拽入口已补齐，但 ArkUI 的 170ms 长按触发、preview
视觉/跟手性、插入线、边缘自动滚动、原版 25%/75% 中央“直接放入”手感、横向阈值及 compact/regular 坐标差异仍需设备验收。M2-U-05 不因本
ADR 整体关闭。
