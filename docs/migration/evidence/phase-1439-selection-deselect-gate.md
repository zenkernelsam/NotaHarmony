# Phase 1439 — 选区种类门控：DESELECT 仅 isf 型选区（证据）

## 原版证据（decompiled_1.4.2，SHA-256 校验提取物）

### 菜单装配器 `urf` / 枚举 `wqf`

- `wqf` 元素选择菜单枚举共 23 项（STYLE、COPY、CUT、DUPLICATE、GROUP、
  UNGROUP、SEND_FORWARD、SEND_BACKWARD、SEND_TO_FRONT、SEND_TO_BACK、
  DELETE、CONVERT_TO_MATH、CONVERT_TO_TEXT、EDIT_MATH、STICKER、CROP、
  FIT_TO_PAGE、FLIP_H、FLIP_V、LOCK、UNLOCK、DESELECT、MORE）。
- `m36`/`urf` 装配器按选区类型（`msf` 层级）条件装配；DESELECT 仅当
  `msfVar instanceof isf` 时加入列表。

### 选区类型层级（`msf` 四实现）

| 类型 | 语义 | 构造点 | DESELECT |
|------|------|--------|----------|
| `isf` | 绘制完成的套索/矩形选区、集合型程序化选区 | `z6c`（hsf 完成转换）、`mud`/`lb8`（集合 select） | **有** |
| `lsf` | 单元素选区（单实体 token `t87`） | `ch1.java:155`（"Finished Text tap selection"）、`hmb.i(t87)` 通用单实体选择 | 无 |
| `jsf` | 组选区（顶层组 token `tof`） | `ch1.java:178`、`j01:87` | 无 |
| `hsf` | 进行中套索选区 | 绘制过程中 | 无（完成后转 isf） |

### `j01.java:59-90` — 粘贴结果选区保种（穷尽分支）

```java
if (msfVar instanceof isf) {
    return lb8.e(isfVar.a.m(j), set, isfVar.d, null, set2, 8);   // isf→isf
}
if (!(msfVar instanceof jsf)) {
    if (msfVar instanceof lsf) return new lsf(t87Var);           // lsf→lsf
    if (msfVar instanceof hsf) { a.d(zg9, "Paste attempted on
        in-progress lasso selection", ...); return null; }       // hsf→拒绝
    js4.t();                                                      // 穷尽
}
tof tofVar = (tof) e52.U3(set2);
if (tofVar != null) return new jsf(tofVar.a, set, tofVar.c);     // jsf→jsf
```

→ 粘贴到既有选区时**保留原选区种类**；无既有选区时粘贴集合经 `mud`
集合 select 产 `isf`。

### 点选路径不产 isf

`tsf` 仅两实现：`rsf`=组（→`jsf`）、`ssf`=单元素（→`lsf`）——选择工具
点选分发永不产 `isf`；`isf` 仅来自套索/矩形完成（`z6c` hsf→isf）与
集合 select（`mud`/`lb8`/`j01`）。

## Harmony 缺口（修复前）

`SelectionState` 无来源标记；`SelectionOverlay` 的 DESELECT 行无条件
装配——点选单元素（lsf 等价）与点选组（jsf 等价）也显示该行，与原版
`urf` 装配不符。

## Harmony 实现

| 位置 | 改动 |
|------|------|
| `SelectionTool.ets` | `SelectionState.supportsDeselectMode`；`beginSelection`/`deselect` 复位；`finalizeSelection` 命中非空→true（hsf→isf）；`selectElementIds` 加 `drawnKind?`（false=lsf/jsf 点选型，true=isf 集合型，undefined=保种）；空结果强制 false；`enterDeselectMode` 同判兜底 |
| `NoteCanvasView.ets` | `applyTapSelect`→`false`；`selectAllPageElements`/全选删除→`true`；图片插入→`selectionVisible ? undefined : finalImages.length > 1`；数学插入→`selectionVisible ? undefined : false`；两处粘贴→`selectionVisible ? undefined : true`（j01 保种）；裁剪重断言/变换重断言省略参数（保种）；`@State selectionCanDeselect` 镜像 + `updateSelectionOverlay` 赋值 + 绑定 |
| `SelectionOverlay.ets` | `@Prop canDeselect`；DESELECT 行 `if (this.canDeselect)` 门控 |

## 判定

- `isf` 专属 DESELECT 语义已对齐。
- 单元素/组点选不再出现 DESELECT 行，deselectMode 入口被同判兜底。
- 图片单插入（`finalImages.length===1`）按 `hmb.i`→lsf 类推判 false；
  多插入按 `mud` 集合判 true——插入路径 select 实现未在反编译层完全
  展开，该近似已在 ADR-1374 登记。

## 验证

- Replay `d02-selection-deselect-isf-gate.mjs`：18/18 green。
- 全量 Desktop Replay：见 report。
- `note@default` / `note@ohosTest` 构建：见 report。
