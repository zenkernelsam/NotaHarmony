# ADR-1137：Compose snapshot 状态层 → ArkUI

## 状态

已接受（Phase 1193）。

## 决策

编辑器 UI = **Jetpack Compose**（`p6a`=`MutableState`/
`osd`/`yjd`=`SnapshotMutationPolicy`/`zjd`/`tjd` snapshot +
`j73` ViewModel）→ Harmony **ArkUI 声明式**（`@State`/
`@Observed`/`@Link`/`@Provide`）—— 响应式状态机
自然对应；`MutableState` Parcelable→sendable；
MutationPolicy→相等策略。

## 理由

`extends osd implements Parcelable,yjd` + `toString
MutableState(value=` + `SnapshotMutationPolicy` + `zjd/tjd`。

## 后果

Compose↔ArkUI 双声明式映射：@State/@Observed 对应
mutableStateOf；@Link/@Provide 对应 remember/hoisted；
快照/MutationPolicy→ArkUI 状态相等语义。
