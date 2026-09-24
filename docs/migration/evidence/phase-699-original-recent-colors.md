# Phase 699 — 原版最近色行（zw1/sw1/ms0/rw1.f）Evidence

## 范围

原版色彩面板（`rw1.c`）中的"Recent colors"行——跨前景/高亮
面板共享、持久化保存的最近用色列表。

## 原版证据（decompiled_1.0.3）

### 1. `zw1.java` / `sw1.java`

- `zw1` = `dx1` 面板项 "RecentColors"（`mli.c` 恒加入面板项集合）。
- `sw1` = `UiState{recentColors: List}` —— 面板 UI 状态。

### 2. `ms0.java` —— 持久化流

```java
// case 6: bhb 记录 → iu1 颜色列表
List list = (List) obj;
arrayList.add(new iu1(kkf.d(((bhb) it.next()).b)));
ol4Var.emit(arrayList, tw1Var);
```

`bhb` 记录经 `kkf.d` 解码为颜色 → `iu1` 列表 → `sw1`。

### 3. `rw1.f` —— 渲染

- 标题行：`ui_tools__recents` 图标 + `ui_tools__recent_colors`。
- `int size = 7 - list2.size();` —— 7 槽上限，不足补透明占位
  `iu1.j`。
- 点击 recent → `ix4Var.invoke(new iu1(j))` 同预设应用路径。

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `bhb` 持久化记录 | `preferences` store `text_color_recents`，key `recents`=JSON 数组 |
| `sw1.recentColors` | `@State colorRecents: number[]` |
| 7 槽上限 | `slice(0, 7)`（加载与记录双向） |
| 两面板共享一份 | 前景 sheet + HSV sheet 共用同一 `colorRecents`（hsvTarget 分派应用管线） |
| recent 点按→应用 | `pickRecentColor` → `pickTextColor`/`toggleHighlightColor` |
| 选色入记录 | `pickTextColor`/`toggleHighlightColor` 入口 `recordRecentColor`（去重前移） |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`

## 验证

- `docs/migration/replays/d02-original-recent-colors.mjs`：
  19 项静态钉全绿。
