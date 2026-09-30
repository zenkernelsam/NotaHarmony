# ADR-1284：页级 op 编解码族

## 状态

已接受（Phase 1342）。

## 决策

页级 op = 结构化 mutation 校验 + BinaryOp 编解码 —
— 对照原版各页操作。

## 理由

`DuplicatePageOpCodec`（对照 `de2.j`：CreatePage+复合
paste op，校验 sourcePageId≠pageId+pageOrderAfter 恰好多
1 页）+ `DeletePageCompensation`/`PageBookmark`/
`PageSnapshot`/`PageReorderPlanner`/`PageBackground`/
`HandwritingConversionMutation`/`PartialEraseMutation`
编解码族 —— 页级变更结构化校验+持久历史记录。

## 后果

页级操作 op 语义与原版一致（复制/删补偿/书签/快照/
重排/背景/手写转换/部分橡皮）。
