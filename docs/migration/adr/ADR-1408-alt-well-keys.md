# ADR-1408: Alt 井选择键（f2 → hxi.a → qxi case0：bxi/dxi/exi）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1473
- **关联**: evidence/phase-1473-alt-well-keys.md
  （`f2:264-276`/`bd8.i0`/`pa8.X,Y`/`qxi case0`/`jyi.A,B,F` 解码）

## 背景

原版键盘兜底链在 PAGE_DOWN 支后实现三组 Alt 修饰和弦，经
`hxi.a` 事件通道（`qxi` case0 消费）操作工具箱井列表：

- `Alt+digit`（`!ctrl && !shift`）→ `bxi(index)`：第 N 色井
  （`jyi.B()` = 按当前工具类型过滤+排序的 `x25` 列表）。
- `Alt+Shift+digit`（`!ctrl`）→ `dxi(index)`：第 N 宽度井
  （`s2k` 列表同型过滤排序 → `k31.Y+r2k` → `jyi.F`）。
- `Alt+[ / Alt+]`（`!ctrl`，shift 不判）→ `exi(∓1)` StepColor：
  色值 `indexOf` 定位当前井、缺失 0 基、floorMod 回卷。

三支 UP 动作、命中即消费。Harmony 已有
`selectFavoriteColor`/`selectWidthWell`（`favoriteColors`/
`widthWells` 按 `activeToolType` 载入，与 `jyi.B()`/`s2k`
过滤语义等价），缺键盘通路。

## 决策

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_LEFT_BRACKET=2059`、
  `ORIGIN_KEYCODE_RIGHT_BRACKET=2060`（SDK 枚举核实）；
  `altWellDigitIndex`（`alt&&!ctrl` + 共享 digit 索引基）。
- `NoteCanvasView` `!textEditing` 块内 PAGE_DOWN 与媒体支之间
  增两支，shift 分流色井/宽度井；均 `return true` 消费。
- `NotePage` 新增 `onKeySelectColorWell`/`onKeySelectWidthWell`/
  `onKeyStepColorWell` 回调 → 既有 VM 方法；VM 新增
  `stepFavoriteColor(delta)` 复刻 exi 色值定位+回卷语义。

## 等价性与边界

| 原版 | Harmony | 一致性 |
|------|---------|--------|
| `bxi`：alt&&!ctrl&&!shift+digit | `altWellDigitIndex` + `!shift` 分流 | ✓ |
| `dxi`：alt&&!ctrl&&shift+digit | 同 helper + `shift` 分流 | ✓ |
| `exi`：alt&&!ctrl+[/]，shift 不判 | `keyChordAlt && !ctrl` 不查 shift | ✓ |
| `jyi.B()` 类型过滤+排序列表 | `favoriteColors`（activeToolType 载入） | ✓ |
| `e52.s3` 越界 → no-op | 越界 return false | ✓ |
| exi 色值 indexOf + floorMod | `indexOf(brushColor)` + `((i+d)%s+s)%s` | ✓ |
| DOWN 消费不动作 | `isUp` 门 + 无条件 `return true` | ✓ |

## 验证

- `d02-original-alt-well-keys.mjs`：33 checks 全绿。
- `note@default`/`note@ohosTest` 构建成功。
