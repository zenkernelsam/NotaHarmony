# ADR-1120：墨迹笔画渲染模型（ka8/i5g/InkStyle）

## 状态

已接受（Phase 1176）。

## 决策

- `t16`=`InkStyle` 枚举 **直接保留** —— `VARIABLE_WIDTH`
  /`FIXED_WIDTH`/`DASH`/`DOTS` 4 值字面 + byte 序
  （对齐 `core.flatbuffers.InkStyle` schema）。
- `i5g` 笔画样式 `{颜色,尺寸,InkStyle,2×bool}` → Harmony
  等价 struct。
- `ka8` 笔画 `{outline Path,fill Path,points,style,width}`
  → Harmony `Path2D`/`drawing.Path` 渲染结构。

## 理由

`t16` 枚举恢复出 4 名+byte 序；`i5g{int,float,t16,bool,
bool}`；`ka8{2×Path,List,i5g,Float}`。

## 后果

墨迹管线：预测输入→`ka8` 笔画模型（Path+样式）→
Canvas drawPath；InkStyle 4 值语义全保留；压感可变
宽（VARIABLE_WIDTH）为默认。
