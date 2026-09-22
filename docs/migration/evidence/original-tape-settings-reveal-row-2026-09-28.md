# 证据：原版胶带工具设置页内的 Hide/Reveal Tapes 行（2026-09-28，Phase 588）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0.3 反编译）。

## 1. 行渲染：`o94` case 14（o94.java:271-286）

设置页行按布尔 `z`（`tapesRevealed`）二选一：

- `z`（已揭示）→ 图标 `ui_tools__tape_reveal` + 文案
  `ui_tools__hide_tapes_action`（"Hide Tapes"）；
- `!z`（未揭示）→ 图标 `ui_tools__tape_conceal` + 文案
  `ui_tools__reveal_tapes_action`（"Reveal Tapes"）。

## 2. 行可组合：`ipi.b`（ipi.java:1490-1505）

```java
m18.i(function1, 48dp行高, ..., s01.I(-1118066581, new o94(z, 14), ...))
```

`ipi.b(z, onClick)` 发出 `o94(z, 14)` 行；`y04` recompose lambda 为其
唯一注册点，调用方即胶带工具设置页（`s7f`/`lfe` 族，`mh9` 图案行同在
该设置面内）。行本身是静态组成；动作经 `oh9 → ti9:360 → np0 case5`
作用于全部可见 tape ID（`ti9:362` 空集 no-op）。

## 3. Harmony 对齐（Phase 588）

| 原版 | Harmony |
| --- | --- |
| `ipi.b` → `o94(z,14)` 行在胶带工具设置页 | `ToolboxSettingsDialog` REVIEW 行 ⋯ 菜单（即 Phase 585 `tape_patterns` 行所在设置面）增 Hide/Reveal 项 |
| `z` 翻转图标+文案 | `anyTapeRevealed ? hide_tapes : reveal_tapes` 动态标签（复用 Phase 583 字符串） |
| `oh9 → np0 case5` 全量 toggle，空集 no-op | `onTapeToggle()` → `tapeToggleSignal++` → 画布 `toggleTapesReveal()`（与 ⋮ 选项菜单项同一信号）；`tapeCount > 0` 时才渲染该行，与 ⋮ 菜单一致 |
| 行与图案行同属胶带设置面 | 与 `tape_patterns` 项同在 REVIEW 行菜单 |

## 4. Replay

`docs/migration/replays/d02-original-tape-settings-reveal-row.mjs`
（11 项断言）。
