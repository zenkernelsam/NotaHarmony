# Phase 1193 证据 — Compose snapshot 状态层（p6a=MutableState）

来源：`defpackage/{p6a,osd,yjd,zjd,tjd,cvc,dve}.java`。

## `p6a extends osd implements Parcelable,yjd` = **`MutableState`**

```java
toString: "MutableState(value=" + zjd.c + ")@" + hash
o14.l("Only known types of MutableState's
      SnapshotMutationPolicy are supported")
```

**Jetpack Compose `MutableState`** —— `osd`=快照态基、
`yjd`=`SnapshotMutationPolicy`、`zjd`/`tjd`=快照内部 —
编辑器 UI 用 **Compose 可观测态**（`mutableStateOf`）。

## Compose snapshot 内部类型（实名坐实）

```
j73  = ViewModel iface         // n73/od8 → ViewModel
p6a  = SnapshotMutableState    // mutableStateOf
osd  = SnapshotState 基
yjd  = SnapshotMutationPolicy  // structuralEquality/neverEqual…
zjd/tjd = snapshot 快照内部
```

## `cvc` = `{u4g a, u4g b}` —— 文本范围（双锚 u4g）

`dve` = undo 逆 op `{int a, long d/e/f, bool g,…}`。

## 判定

**编辑器 UI = Jetpack Compose**：
- `MutableState`/`SnapshotMutationPolicy`/`snapshot` 响应式
  状态机（`vle` VM 的 `p6a` 字段）。
- 文本范围 `cvc{u4g×2}` + undo 记录 `dve`。
- `*le` = 编辑器态 lambdas（`tle`/`qle`/`ple`）。

## Harmony 决策

- Compose `MutableState`/`snapshot` → Harmony **ArkUI
  `@State`/`@Observed`/`@Link`/`@Provide`**（响应式状态，
  Compose 声明式 UI↔ArkUI 声明式 UI 自然对应）。
- `SnapshotMutationPolicy`（equality/never）→ ArkUI
  状态相等策略（`@Observed` 深度/引用比较）。
- `MutableState` Parcelable → Harmony `sendable`。

## 产出

- fixture `d02-compose-state.mjs`（10 断言）。
- ADR-1137；中文报告。
