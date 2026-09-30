# ADR-1181：ls StrokeInput 对账 + link 粘贴

## 状态

已接受（Phase 1237）。

## 决策

`ls` lx5.j.d Map+MotionEvent↔StrokeInput 对账+ClipData
link → Harmony `onTouch`+自研 stroke-input（或
fail-closed）+`pasteboard` URI。

## 理由

`ls` 收集器：`lx5.j.d`=`jw5→hx5(matrix,ts,input)` 每笔
状态 + MotionEvent-start/StrokeInput-finish 警告 +
ClipData "link" 粘贴 —— 输入生命周期一致性。

## 后果

Harmony 输入对账 = onTouch+stroke-input+pasteboard
—— 生命周期校验语义保真。
