# 证据：原版胶带图案选择器（mh9 → t7f → nh9，2026-09-28，Phase 585）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0.3 反编译）。

## 1. 入口与表面

- 胶带工具设置页（`s7f`/`mth.a`/`o79` default case）内的图案行由
  `lfe.b` 渲染——当前图案小样 + 工具色。
- `ys2:1410` 创建 `i31(28, ix4)` 派发器；`i31` case 28 → `mh9(mv6)`。
- `ti9:352-354`：`mh9` → `bi9` variant 3 → `asd.k(null, k1a(true,
  t7f(mv6)))` —— `t7f` 为底栏/弹层内容标记（`u7f` 实现）。
- `jhe:194-212`：`u7fVar instanceof t7f` → `lfe.a(y5f.g(r5fVar),
  kkf.d(y5f.d(r5fVar)), i31(26, ix4))` —— 即 `lfe.a(当前图案序数,
  工具色, nh9派发器)`。

## 2. 选择页内容 `lfe`

- `lfe.a`（line 10）：`List = [STRIPES, GRID, DOTS, PLAIN, STARS,
  FLOWERS, HEARTS, WAVES, CHECKERS]` —— `ife` 声明序，9 项。
- 每项 `c(ife, selected, color, onClick)`：`z = i == ife.I` 标选中；
  `onClick = ej9(29, ix4, ifeVar)` → `ej9` case29 →
  `ix4(Integer(ife.I))` → `i31` case26 → `nh9(图案序数)`。
- `lfe.d`：单图案小样——`ui_tools__tape_pattern_*` 9 个 drawable
  按序数映射。
- `ife.I`（ife.java:29-37）：`byte` 字段 = 声明序数 0..8，与 Harmony
  `TapePattern` 枚举一一对应。

## 3. 选择写入 `nh9` → `yh9`(i3=1)

`ti9:356-357`：`nh9` → `yh9` variant 1（`invokeSuspend` default 分支）：

```java
r5f r5fVarH = ti9Var.Y.getValue();          // 当前工具态
g5f g5fVar = r5fVarH instanceof g5f ? (g5f) r5fVarH : null;
if (g5fVar != null) {
    r5fVarH = g5f.h(g5fVar, null, i2, 15);  // 复制并替换 tapePattern 字段
}
u5f u5fVarR = ti9Var.r(r5fVarH);            // 重建 ToolState
ti9Var.q(u5fVarR);                          // 应用 + 持久化
```

`g5f.h(g5f, e31, int i, int mask)` 返回 `new g5f(e31, i3, i4, i5, i)` —
字段 `e`（`y5f.g` 读取的同一字段）= tapePattern 序数。持久化落
`tool_state.tape_pattern`（`ToolStateEntity.tapePattern`，Phase 576 已对齐）。

## 4. Harmony 对齐（Phase 585）

| 原版 | Harmony |
| --- | --- |
| `s7f`/`lfe.b` 图案行 → `mh9` | `ToolboxSettingsDialog` REVIEW 行 ⋯ 菜单增 `tape_patterns` 项 → 打开选择面板（表面偏差：原版在胶带工具设置页内，Harmony 无单工具设置页，置于工具箱设置对话框） |
| `t7f` + `lfe.a` 9 图案按序、工具色小样、选中态 | `TapePatternPicker`：`TAPE_PATTERN_ORDER` 同序 9 小样，`tool.brush.color` 着色，`tool.tapePattern === pattern` 标选中 |
| `lfe.d` 图案小样 drawable | `TapePatternSwatch`：合成笔画经 `renderTapePattern` 实绘（带体色 + 图案层）；PLAIN 绘纯色带 |
| `nh9` → `g5f.h` 复制 → `ti9.q` 应用持久化 | `EditorViewModel.setToolTapePattern(toolId, pattern)`：`updateState` 写 `state.tapePattern` → `saveToolState`（tool_state.tape_pattern）；激活行经 `applyActiveState` → `activeTapePattern` 即时生效 |

## 5. Replay

`docs/migration/replays/d02-original-tape-pattern-picker.mjs`（25 项断言）。
