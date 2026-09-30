# ADR-1188：长按 fire-vs-cancel

## 状态

已接受（Phase 1244）。

## 决策

`g2` delay→`gwa` fire + `b14.dispose`/`i2`→`ewa` cancel
→ Harmony `onLongPress`+delay 协程+dispose→cancel。

## 理由

`fwa`↔`gwa`(fire)/`ewa`(cancel) 1:2 = 长按按住到阈值
`g2`→`gwa`，提前松开/dispose→`ewa` —— 长按二分。

## 后果

Harmony 长按 = onLongPress+delay+dispose —— fire/
cancel 语义保真。
