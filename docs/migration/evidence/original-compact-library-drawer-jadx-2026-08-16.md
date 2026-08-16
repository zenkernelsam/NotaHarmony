# 原版资料库 compact drawer 与 Harmony 移植证据（2026-08-16）

## 范围与结论

本证据对应 M2-U-03。基准是
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`，移植侧是
`note/src/main/ets/ui/library/LibraryPage.ets`。结论是：原版在窄于 840dp 时仍保留文件夹入口，
只是把常驻 sidebar 改为可开合的 drawer；Harmony 侧现以 ArkUI `overlay + Stack + List` 实现等价的
可达性，并明确把这是 Harmony API 适配写法，不冒充原版 Compose 常量。

## 原版硬证据

- `ta7.java:58` 以 `q8gVar.a(840)` 区分常驻 sidebar 与窄屏 drawer；同一方法 `:104` 使用
  `952dp -> 332/280dp`，`:111-116` 使用 `1400dp` 和 `600dp` 决定列数。
- `ta7.java:63` 建立 `hp3` drawer state。`fh3.java:58` 的错误文案直接提到
  `ModalNavigationDrawer` / `DismissibleNavigationDrawer`，证明不是把 folder 列表永久删除。
- `gsi.java:612,736,1439` 读取 `fq4.l()`，分别处理展开/折叠状态并递归渲染子 folder；`dq4.java`
  的模型还保留 parent、direct children、note count、selected/expanded 等语义。
- `zri.java:37-40` 提供 “Folders” 标题和 Add 入口；`vc2.java:323,340,349` 提供新增、重命名、删除
  folder 操作。原版 folder row 使用约 48dp 的触控预算，并有选中态/chevron。

## Harmony 侧实现

`LibraryPage.ets` 的 compact 路径现在包含：

1. `@State compactFolderDrawerVisible` 和 `open/closeCompactFolderDrawer()`；页面根节点以
   `overlay(this.CompactFolderDrawer())` 承载抽屉，遮罩点击或关闭按钮可收起。
2. 44vp 汉堡入口与当前位置按钮；当前位置始终来自 `currentFolderName()`，不会因抽屉关闭而丢失。
3. 抽屉标题、全部笔记、垂直原生 `List`、新建文件夹和 280--320vp 的 bounded drawer 宽度；同一
   `FolderNavigationList` 也由 regular sidebar 复用。
4. `expandedFolderIds`、`hasChildren`、`expanded` 和 `folderListItems(false)`：folder row 由 chevron
   展开/折叠，选中项显示勾选，行高为 48vp；每行的原生 `bindMenu` 仍可执行新建子文件夹、重命名、
   移动和删除。
5. 常规 sidebar 复用同一行与同一个 `List` builder，不再因 folder 数量变多而把新建按钮推出屏幕；
   Phase 254 在该容器上增加原生拖拽事件，不改变本证据的 compact 可达性结论。
6. 重新加载或删除后会裁剪失效的展开 ID，并自动展开当前 folder 的祖先；折叠合法父节点时不会把其
   子节点错误当作孤儿重新显示。

## 适配决策与边界

- `overlay/Stack` 是 ArkUI 侧适配决策；JADX 只证明原版 DrawerState/导航语义，不提供 Harmony 的
  `overlay` API 或本项目的 280--320vp 数值。
- 该实现保证点击、滚动、选择和操作入口的静态可达性；抽屉动画、滑动手势、字体度量和真实触控
  仍需 360x800、600x960、1280x800 设备/Hypium 验收。
- 未把原版 folder 的颜色、emoji、嵌套笔记计数臆造进 Harmony 数据模型；M2-U-03 只补导航与操作
  可达性，模型扩展另按审计任务处理。

## 回放

`node docs/migration/replays/d02-original-compact-library-drawer.mjs` 输出：

```text
D02_ORIGINAL_COMPACT_LIBRARY_DRAWER_REPLAY_OK drawer-state=1|folder-scroll=1|tree-expand-collapse=1|selection-check=1|folder-actions=1|compact-hit-targets=1|original-thresholds=1
```

全量桌面回放共 236 个 `.mjs`，`FAILED=0`。这两项均为桌面静态/Node 回放，不替代设备验收。
