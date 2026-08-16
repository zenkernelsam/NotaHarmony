# 原版文件夹索引拖拽与 Harmony child-index 移植证据（2026-08-16）

## 范围与结论

本证据对应 M2-U-05 / ADR-0231。原版基准为
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3` 与 1.0.3 APK `classes2.dex`；移植侧为
`FolderRepositoryImpl.ets`、`LibraryPage.ets` 和 `FolderRepository.test.ets`。结论是：原版拖拽的稳定业务契约是
`folderId + parentId + childIndex`，横向位置决定层级；Harmony 现保持该契约，只把 fractional position 适配成事务
内连续 child index。另经 OpenHarmony 6.0 Release 引擎源码确认，ArkUI `List.onItemDrop.insertIndex` 是从源项仍在
列表中的原始 `itemPosition_` 计算，当前向下拖动时先扣除源子树的换算不是猜测，而是匹配引擎契约。

## 原版硬证据

- `cm3.java:9-13,54-58` 明确输出
  `DragFolderResult(folderId=..., parentId=..., childIndex=...)`。
- `id7.java:170-172` 把 folderId、parentId、index 与时间交给 `xdb`；`sad.java:94-106` 继续传递三元组并在成功后
  更新展开状态。
- `xdb.java:94-104,129-139` 对目标父级 children 使用 child index：空列表为 `0.0`；首项前为
  `children[i].position - 1`；末项后为 `children[i-1].position + 1`；中间为前后 position 平均值。
- `gsi.java:962-978` 把 48dp 与 24dp 传入 `im3`。`im3.java:132-198` 的 helper 按父级求 child index，
  `:213-220` 最终创建 `cm3`。
- 对 APK `classes2.dex` 的 raw `dm3.invoke()` 复核确认：拖拽横坐标除以 24dp 并取整数作为目标 depth；纵向用
  48dp 行预算，候选行前 25%、中间 50%、后 25% 分别形成 before、inside、after，再由相邻扁平行深度回推
  parentId 与 childIndex。这补足了 JADX 对 `dm3.invoke()` 跳过反编译的缺口。

## ArkUI insertIndex 契约证据

- 对应项目 API 21，复核 OpenHarmony `arkui_ace_engine` 的 `OpenHarmony-6.0-Release`，提交
  `5d55560ccaec9f4df291f7d894aef914b7873297`。
- `list_event_hub.cpp:167-183` 的 `GetListItemIndexByPosition()` 直接转给
  `ListPattern::GetItemIndexByPosition()`；拖拽开始的 strict 分支才用于取得原始 source index。
- `list_pattern.cpp:2863-2894` 遍历当前 `itemPosition_` 并返回命中的原列表 index 或末尾 `last + 1`，期间没有删除、
  隐藏或重排 source item。
- `drag_drop_manager.cpp:1895-1899,1961-1972` 把该结果原样作为 `insertIndex` 交给 `ListEventHub::FireOnItemDrop()`；
  `list_event_hub.h:154-161` 又把同一对 `itemIndex, insertIndex` 传给 `onItemMove` 与 `onItemDrop`。
- `js_list.cpp:747-779` 要求 `onItemDragStart` 返回带 `builder` 的对象，非对象返回值在 `:759-761` 直接成为
  `nullptr`；`list_event_hub.cpp:88-99` 又会在 custom node 为空时终止起拖。因此 Harmony 回调不能只捕获状态后
  返回 `void`，必须返回实际 preview builder。
- 因而同列表向下拖动必须先把 source（本项目还包括其可见子树）从原始扁平边界中扣除，再计算目标 child index。
  fixture 明确覆盖单项向下落在末项前/后的 `3 -> 2` 与 `4 -> 3` 换算，防止偏一位回归。

## 发现的移植差异

旧 Harmony 仓储只接受 `moveFolder(folderId, newParentId)`，跨父级时一律追加；资料库没有 List drag callback，且
folder 行缩进只有 12vp。即便 parent/siblingOrder 模型已经存在，也无法表达原版任意 child index，更无法用横向
拖动进入空文件夹。

## Harmony 实现

1. `planFolderMove()` 接收可选 insertIndex，先按稳定 sibling order 排除源 folder，再在目标 child index 插入；跨父级
   同时产生 old/new sibling 序列。
2. `moveFolder()` 在共享 metadata mutex 和单事务中更新 parent，再逐行写回两组连续 sibling index；任一影响行数不是
   1 即回滚。
3. `resolveFolderDrop()` 同时接收可见 ID、可见 depth、ArkUI insert boundary 与 requested depth。源 folder 的整棵
   可见子树先从引擎的“源项仍在列表”扁平边界移除，之后按目标 depth 找最近祖先并计算其 child index。
4. `LibraryPage` 把 regular/compact folder tree 统一为 `List`；开始拖拽时捕获 ID/depth/source/x anchor。缩进改为原版
   24vp，drop 的横向位移换算 requested depth；`onItemDragStart` 返回真实 ArkUI builder，避免只有回调却因空预览节点
   无法起拖。
5. “上移/下移”和显式父级菜单保留为键盘、无障碍与失败后备。

## 适配差异与未闭环

- 原版存 fractional position；Harmony 写连续整数。这是存储适配，不改变 parentId + childIndex 的可见顺序。
- ArkUI 回调提供 insert boundary，而不是原版完整的 25%/75% hover state machine；当前静态实现补齐横向层级、空父级、
  before/after 顺序与可用 preview builder，但中央直接放入、插入线、preview 视觉/跟手性、自动滚动与阈值仍需设备
  验收。
- 原版六层、同级重名和自身子树规则仍由统一 validator 最终裁决，拖拽 helper 不绕过仓储约束。

## 回放

`node docs/migration/replays/d02-original-folder-indexed-drag.mjs` 输出：

```text
D02_ORIGINAL_FOLDER_INDEXED_DRAG_REPLAY_OK parent-child-index=1|before-middle-after=1|arkui-pre-removal-boundary=1|subtree-unit=1|horizontal-depth-24dp=1|drag-preview-builder=1|empty-parent=1|contiguous-transaction=1|fallback-actions=1
```

全量桌面 replay 为 `REPLAY_FILES=240 FAILED=0`。这些是静态/模型证据，不替代设备手势验收。
