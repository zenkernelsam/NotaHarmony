# ADR-1264：Form 卡片（≈ widget）

## 状态

已接受（Phase 1320）。

## 决策

AppWidget→`FormExtensionAbility`+`formBindingData`+
`widget_bindings`；配置页→`FormEditAbility` —— widget
语义保真（含原版文案/空态）。

## 理由

`NoteFormAbility`（FormExtensionAbility+3 卡 feed+
widget_bindings 绑定）+5 卡面（NewNote/NewRecording/
RecentNotes/FolderNotes/NoteThumbnail —— 逐项对照原版
provider+intent+extra+文案："No recent notes"/"No notes
in this folder"/"Choose a note"）+2 FormEditAbility —
— widget 逐项保真移植。

## 后果

widget 全功能+原版文案/空态/点击 intent 保真 ——
AppWidget→Form 语义映射。
