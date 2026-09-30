# ADR-1274：渲染合成（部分橡皮+分层）

## 状态

已接受（Phase 1330）。

## 决策

部分橡皮 = 几何裁剪（实体拆分）+ 分层合成 +
destination-out 擦除 —— 对照原版 `w4b`/`h4f`。

## 理由

`EraserEngine.erasePartial` 把命中的 Ink 裁剪成零/
多个残余（`partialReplacements`）+删源实体（对照
`w4b`/`h4f` clip 语义——原版部分橡皮不保留 tool 5）；
`StrokeLayerManager` 分层合成（completed+current→
main + 脏区 `clip()` + destination-out 橡皮）。

## 后果

部分橡皮实体拆分+分层合成与原版一致 —— 渲染保真。
