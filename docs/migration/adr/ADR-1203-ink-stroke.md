# ADR-1203：ka8/i5g/t16 墨笔迹模型

## 状态

已接受（Phase 1259）。

## 决策

`ka8{Path,List,i5g}`+`i5g{color,size,t16}`+`t16` 枚举
→ Harmony `Path2D`/`canvas.Path`+工具枚举。

## 理由

`ka8`=笔迹可绘制（Path+点+InkStyle+次Path+width）；
`i5g`={color,size,t16 tool,bool×2}；`t16`=VARIABLE_
WIDTH/FIXED/DASH/DOTS —— 笔迹模型。

## 后果

Harmony 笔迹 = Path2D+工具枚举 —— 笔迹语义保真。
