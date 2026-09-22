# 证据：deselectMode 点按命中测试白名单（xtc.a(jE, ftc.g)）

日期：2026-09-23 · Phase 612

## 原版调用链（decompiled_1.0.3/sources/defpackage）

| 位置 | 行为 |
| --- | --- |
| `dl1.java:105-111` | `ftc.h=true`（deselectMode）按下：`Set set = ftcVar.g`（选中 id 集）→ `xtc.a(jE, set)`；`otc` 命中 → `stc` 移出选区 |
| `xtc.java:25-28` | `a(j, set)` → `fu1.e(j, x09, set)` |
| `fu1.java:270-303` | `e()`：第一程点精确命中 + 第二程 ±5 容差复测，`set` 全程过滤——`set==null || set.contains(ly3.id)` 白名单语义 |
| `fu1.java:445` | `f()` 区域命中同 set 参语义 |
| `dl1.java:112-119` | 未命中（白名单内无元素）→ `yxi.e` 覆盖层内判：内 → `utc` 抑制；外 → `qtc` 取消 deselectMode |

语义核心：**白名单在命中测试内部**——未选中元素即使 z 序压在
选中元素之上也不构成遮挡，点按穿透到下方被选中元素。

## Harmony 移植前差异

`deselectTargetIdsAt` 用 `topmostPageElementIdAt(point)` 在全集
取最上层，再 `selected.has(hitId)` 判否——顶层未选中元素会
挡住下层被选中元素：用户点按一个被覆盖的已选元素意图取消
选中，命中落空按 utc/qtc 处理（抑制或退出模式），与原版
"穿透到被选中元素并移除"不符。

## 对齐实现

- `hitOrderedElementIdAt`/`topmostPageElementIdAt` 增加可选
  `whitelist: Set<string>`——`!whitelist.has(id) → continue`
  （`fu1.e` `set==null||set.contains` 等价），两程命中共用。
- `deselectTargetIdsAt` 先建 `selected` 扁平 id 集（
  `ftc.g`/`h()` 等价），再 `topmostPageElementIdAt(point, selected)`；
  组叶解析逻辑不变（白名单含组内成员 id——`h()` 为扁平集）。
- 其余 `topmostPageElementIdAt` 调用点默认 `null`——普通点按
  不过滤（`fu1.e` set=null 等价）。

## 行为差异用例

选区含元素 A，未选中元素 B 压在 A 上：
- 原版 deselectMode 点按该位置 → A 移出选区。
- 旧 Harmony → 命中 B，B 未选中 → 落空（utc/qtc）。
- 新 Harmony → 白名单内最上层为 A → A 移出选区。
