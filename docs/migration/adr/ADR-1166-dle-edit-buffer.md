# ADR-1166：dle = TextEditBuffer

## 状态

已接受（Phase 1222）。

## 决策

`dle` TextEditBuffer（`replace`/`setComposingRegion`/
`setSelection`/`finishEditing→rnh`/`abort`）→
Harmony 编辑缓冲（同名语义 + `o7a` gap 缓冲 +
四重 `rh8.v` 钳位保留）。

## 理由

`b(i,i2,i3)`=setComposingRegion、`c`=replace 四钳位、
`e`/`f`=composition/selection、`a()→rnh`=finishEditing、
`w`=abort —— Compose 实名方法对齐。

## 后果

Harmony 编辑缓冲 = replace+组合区+选区+提交/放弃
—— 与原版 TextEditBuffer 方法逐一对应。
