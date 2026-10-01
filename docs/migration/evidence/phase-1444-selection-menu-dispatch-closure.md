# Phase 1444 — sqf 菜单动作分发侧审计收口（证据）

## 原版分发器（decompiled_1.4.2 `sqf.java`，`wqf.ordinal()` switch）

逐 case 对照 Harmony `onSelectionMenuAction`：

| case | 项 | 原版分发 | Harmony 对照 |
|------|----|----------|--------------|
| 0 | STYLE | lsf+vvh→`hrf` 文本框事件（h35.S0 调试旗，生产藏）；否则 h() 成员先 `zq.c0`→mn7 笔画、再 `zq.v0`→f5g 形状扫描，任一命中出行 | `selectionCanStyle`=strokes‖shapes ✓ |
| 1 | COPY | `ot2.d`：剪贴板写入 + `omeVar.a()` 自清选区 | `copySelectedToClipboard`+`clearSelectionWithRegisterReset` ✓ |
| 2 | CUT | `qrf`→`ot2.e` 协程（剪贴板+删除） | CUT 管线 + 清选区 ✓ |
| 3 | DUPLICATE | `qrf`→`ot2.a`：`omeVar.a()` 清选区→`f()` 偏移粘贴（宽 10%、max30）→j01 产 isf | `pasteClipboard(nudge)`→`selectElementIds(true)` ✓ |
| 4 | GROUP | isf 且 `N3(q+m)≥2` → `p2d` + `H.a()` 清选区 | `members.length<2` 拒 + 清选区 ✓ |
| 5 | UNGROUP | jsf→`x2(jsf.a)`；isf 纯单组→`z2(m 单例)`→`trf` | `selectedGroupIds.length!==1` 门 ✓ |
| 6/7 | SEND_FWD/BWD | `urfVar.F(g0c(5,±))` | `bringSelectionForward/Backward` ✓ |
| 8/9 | TO_FRONT/BACK | `urfVar.F(naf(23/24))` | `sendSelectionToFront/Back` ✓ |
| 10 | DELETE | `p2d(24)+H.a()` | 删除+清选区 ✓ |
| 11/12 | CONVERT_* | `urfVar.T.d()` 可用性门→确认流/Toast | fail-closed（ADR-1377） |
| 13 | EDIT_MATH | lsf+cv9→`gv9` 事件 + `urfVar.H()` 面板态 | `startMathEditing` ✓ |
| 14 | STICKER | 状态门 + `trf` | fail-closed（rd5） |
| 15 | CROP | lsf+l97→`f11` 参数→`erf` 会话态 | `startImageCrop` ✓ |
| 16 | FIT_TO_PAGE | `throw NotImplementedError` | 死项缺省 ✓ |
| 17/18 | FLIP_H/V | `psb(h(),ei5.F/G)` + `H.a()` 清选区 | `flipSelected`+清选区 ✓ |
| 19/20 | LOCK\|UNLOCK | lsf→`ybn` 实体 `t()` 翻转；非 lsf→`A()` 方向→`hp8` 批量 + `omeVar2.a()` | `setSelectedPositionLocked`+清选区 ✓ |
| 21 | DESELECT | `dqd(16)`→isf.h 模式位，isf.j 克隆存 `m` 快照 | `enterDeselectMode`+`preDeselectSelection` ✓ |
| 22 | MORE | `frf.b` 子菜单展开位翻转 | 平铺适配（ADR-0645/1375） |

## 关键澄清

- `urfVar.H.a()` = `ome.a()` = `hmb.g(null)` = **清选区状态流**——原版
  GROUP/UNGROUP/DELETE/FLIP/LOCK 动作后选区全清，Harmony 逐一对应。
- `urfVar.H()`（EDIT_MATH 尾）= 面板态转移 `lrf.a`，非清选区。
- `urfVar.I(mrf,mrf2,bz5)` = CONVERT 确认流：bz5→`ns6` 资格判定，
  ms6 直转 / ls6 走 `aff` 协程转换 / ks6 取消——iink 链 fail-closed。

## 结论

分发侧 23 case 全部对齐或登记 fail-closed——无新增缺口。
