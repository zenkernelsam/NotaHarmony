# Phase 1445 证据 — deselectMode 点除语义与钉住选区界（mud case7 / zf3 / m5b 13-14）

## 原版证据（decompiled_1.4.2）

### isf 字段定稿（isf.java）

| 字段 | 语义 |
|------|------|
| `a`/`b`/`c` | sbe 三元组——`a`=选区界（hsf→isf 转换时取 `hsfVar.b` 绘制区域，z6c case6）；`b`=变换演化界（`e()` 经矩阵变换）；`o=hsm.b(a,f,m)`=a∪组界=**可见轮廓+命中域**（`msf.b()`） |
| `g` | 全部选中叶子 id 集（`h()`） |
| `m`/`n` | 选中组对象集（`tof`）及其 finalized 副本 |
| `p` | `m` 成员并集（`c()`） |
| `q` | `g−p` 非组叶子集（`f()`，urf SEND_* 门控集） |
| `h` | deselectMode 模式位 |
| `i` | 已点除 id 累计集（渲染经 `hak.o0` 分区消费） |
| `j` | `bpj` 选区会话 UUID（构造时铸，`j()` 不可覆写） |
| `k`/`l` | lassoPoints / finalizedLassoPoints |

### 模式进出（dqd.java case16/17 + sqf case21）

- `sqf` case21（DESELECT 菜单动作）：`omeVar3.a.f(new dqd(16))` 把流内 isf 拷贝为 `h=true`（掩码 16255，仅覆写 bit7）；随后 `omeVar3.m = isf.j(...,h=false,...)` 存**入模前快照**到 `ome.m`。
- `dqd` case17（出模式）：掩码 15999 → `h=false` + `i=∅`。

### 点按分发（zf3.java:106-152）

仅 `isfVar.h=true` 时产事件；命中测试白名单 = `g`（`dtfVar.a(jE, set)`）：

- `ssf` 单元素命中且 id∈g → `ysf({id}, null)`——剔单成员。
- `rsf` 组命中（`tof.b`∩g≠∅）→ `ysf(tof.b, tof.a)`——**整组叶子 + 组 token 一起剔**。
- 界内空点（`f5n.h(a, jE, d, …)` 命中但不在成员上）→ `atf`=None。
- 界外 → `wsf`=CancelDeselectMode。

### 点除变换（mud.java case7，d9c.java:255 驱动）

```
g′ = y2g.d0(g, set6)        // 剔除命中叶子
i′ = y2g.f0(i, set6)        // 累计已点除
m′ = n′ = m − {tof.a==t87}  // 组 token 非空则整组出 m/n
a/b/c/j/h 保留（掩码3775只覆写 g/i/m/n）
g′.isEmpty() → return null  // 选区消亡
```

**关键**：`a`（选区界）在点除中**不改**——`o=a∪m` 全程钉住，轮廓不随成员缩减；界内/界外判定同用 `a`。mud 返 null → `d9c` 置 `ome.m=null`（快照弃置，取消不可达）。

### 确认/取消（m5b.java case13/14，经 dhi:494/502 反射注册）

- case13 `onConfirmDeselectMode`：`ome.m=null` + `dqd(17)` 变换当前 isf → 缩减保持。
- case14 `onCancelDeselectMode`：取 `ome.m` 快照，`htd(isfVar3,5)` 回灌——`htd` case5 守卫：仅当流内值仍是 `isf` 且 `h=true` 且 `j`（选区会话 UUID）与快照相同才替换为快照；否则保持现状。

## Harmony 落点与缺口修复

### 本 Phase 修复（真实缺口）

- **缺口**：Harmony `updateSelectionOverlay` 的 `selectionRect` = 存活成员 union——点除模式下每剔一个成员轮廓即收缩；原版 `isf.a`/`o` 在 `mud` case7 中保留，轮廓钉住不收缩（界内/界外判定亦同域）。
- **修复**：`SelectionState.deselectBounds` = 入模界（`enterDeselectMode(bounds)` 由调用方传 `selectionBoundsCanvas()`）；`updateSelectionOverlay` 尾段 `deselectMode && deselectBounds!=null` 时用钉住界替代成员 union。`confirm`/`cancel`/`deselect`/`beginSelection`/`selectElementIds` 五路清零。
- **加固**：`deselectElements` 增 `if (!deselectMode) return`——`zf3` 仅在 `h=true` 时产 `ysf`，非模式调用为死路径同判兜底。

### 本 Phase 审计确认一致（无需改动）

- 组内成员点按→整组剔除：`deselectTargetIdsAt` 命中属组叶子 → `{leaves, [groupId]}` ↔ `ysf(tof.b, tof.a)`。
- 界内空点不动作 / 界外取消恢复：`deselectTargetIdsAt` null + `pointInSelectionRect` 分派 ↔ `atf`/`wsf`。
- 确认保留缩减 / 取消恢复快照 / 快照弃置（`deselect()`→`preDeselectSelection=null` ↔ `ome.m=null`）。
- `j`=UUID 守卫：Harmony 模型中快照与模式同生共死（selectElementIds/deselect 皆清），`htd` case5 的拒恢复支不可达——等价。

## 验证

- `d02-deselect-mode-pinned-bounds.mjs`：14/14。
- `d02-original-deselect-mode.mjs`（更新入模签名 pin）：22/22。
- `d02-selection-deselect-isf-gate.mjs`：18/18。
- 全量 Desktop Replay 基线 1295/1295；`note@default` 与 clean `note@ohosTest` 双构建通过。
