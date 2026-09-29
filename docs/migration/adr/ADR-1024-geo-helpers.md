# ADR-1024：几何助手 = tombstone 标志 + 平移 + 页旋转

## 状态

已接受（Phase 1080）。

## 决策

- tombstone = 表中 Boolean 标志（`ba6.K`）。
- `h0` = 包围盒按 `fqa` 平移；`ba6.i` = PDF 页旋转矩形
  （0/90/180/270，其余遥测+原样 fail-soft）。

## 依据

`o(get,TRUE)` + `h0`/`i` 公式 + RENDERER 遥测。

## 后果

Harmony 页旋转仅支持直角；非常规度数记遥测不崩。
