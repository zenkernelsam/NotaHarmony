# 证据：原版 Tape 工具入箱（REVIEW 默认工具态，2026-09-28，Phase 584）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0 反编译）。

## 1. 工具枚举 `a6f.java`

`a6f` 静态字段映射（字段声明顺序 + `V` 数组一致）：

| 字段 | 名称 | 序数 |
| --- | --- | --- |
| I/J/K/L/M | PEN/PENCIL/HIGHLIGHTER/TEXT/ERASER | 0-4 |
| N/O/P/Q | SELECT/MEDIA/RECORD/POINTER | 5-8 |
| R | LASER | 9 |
| S | **REVIEW** | 10 |
| T/U | RULER/ZOOM | 11-12 |

## 2. 默认工具箱 `rz1.java:1070/1075`

Primary 托盘：`u5f(PEN,0) (PENCIL,1) (HIGHLIGHTER,2) (ERASER,3)
(TEXT,4) (SELECT,5) (MEDIA,6) (RECORD,7)`。

Secondary 托盘（`rz1:1075`）：

```java
u5f(10, 1, a6f.Q /*POINTER*/, 0, null, null, null)
u5f(0,  1, a6f.R /*LASER*/,   1, w31(-1754827, 15.0f, num, 0, 0, null, 36), null, null)
u5f(0,  1, a6f.U /*ZOOM*/,    2, null, null, null)
u5f(0,  1, a6f.S /*REVIEW*/,  3, w31(-1706497, 36.0f, num, 0, 1, 0, 4), null, null)
u5f(0,  1, a6f.T /*RULER*/,   4, null, null, null)
```

REVIEW 位于 Secondary index 3（POINTER=0 / ZOOM=2 / RULER=4 未移植，
Harmony 侧留空位语义一致）。

## 3. `w31` = BrushState 字段解码

`w31.toString()`：`BrushState(color, widthSize, style,
selectedColorWellIndex, selectedWidthSizeWellIndex, tapePattern)`。

REVIEW 的 `w31(-1706497, 36.0f, num, 0, 1, 0, 4)`（合成构造器末参 4 =
mask → style=null，tapePattern 参数 = `0`）：

- color = **-1706497**（与已种子化的 5 色井首色一致）；
- widthSize = **36.0f**（三档宽度井 [12,36,64] 的中档）；
- selectedColorWellIndex = **0**，selectedWidthSizeWellIndex = **1**；
- tapePattern = **0** ↔ `TapePattern.STRIPES`（`i16` 缺省 `ife.STRIPES`）。

## 4. 校验规则 `dm2`

`dm2` 校验 CreateInkOp：tapePattern 仅当 `tool == TAPE(u16)` 时合法——
非胶带工具不得携带 tapePattern。

## 5. Harmony 对齐（Phase 584）

| 原版 | Harmony |
| --- | --- |
| `u5f(REVIEW, secondary, idx3)` | `createDefaultStates` 增 `'tape'` 行：`ToolType.REVIEW` + `TRAY_TYPE_SECONDARY` + index 3 |
| `w31(-1706497, 36f, null, 0, 1, 0)` | color=-1706497、width=36、colorWell=0、widthWell=1、`tapePattern=STRIPES` |
| `dm2` tapePattern 仅 TAPE | `getRenderSpec()`：`currentTool === REVIEW ? activeTapePattern : undefined` |
| 5 色井 + 3 宽度井 | `supportsBrushControls` 纳入 REVIEW；井数据早已种子化（rz1.p/s） |
| 工具箱标签 | `toolTypeLabel` REVIEW → `tape_tool` |

已知偏差：存量笔记的工具箱经 missing-defaults 回填路径把 REVIEW 放在
Secondary 尾部（trayType 保留、index 取 primaryCount），与全新安装的
index 3 略有差异；顺序语义（LASER 之后）一致。

Replay：`docs/migration/replays/d02-original-tape-tool-entry.mjs`（16 项）。
