# Phase 1342 证据 — 页级 op 编解码族

来源：`data/{DuplicatePageOpCodec,DeletePageCompensation
OpCodec,PageBookmarkOpCodec,PageSnapshotOpCodec,
OriginalPageReorderPlanner,OriginalPageBackgroundOperation,
OriginalHandwritingConversionMutationCodec,
OriginalPartialEraseMutationCodec}.ets`。

## `DuplicatePageOpCodec`

```
// 原版 de2.j 在所选末页后锚定 CreatePage + 转码内容 op
// 流；Harmony 写一个 CreatePage + 复合 clipboard-paste op，
// 此 payload 即持久历史记录
validate(mutation): sourcePageId≠pageId、pageOrderAfter =
  before + 恰好 1 页 —— 页序变更校验
BinaryOpReader/Writer 编解码
```

→ 复制页 = CreatePage+paste-复合 op（对照 `de2.j`）+
页序变更结构校验。

## 页级 op 编解码族

- `DeletePageCompensationOpCodec` —— 删页补偿 op。
- `PageBookmarkOpCodec` —— 页书签 op。
- `PageSnapshotOpCodec` —— 页快照 op。
- `OriginalPageReorderPlanner` —— 页重排规划。
- `OriginalPageBackgroundOperation` —— 页背景 op。
- `OriginalHandwritingConversionMutationCodec` —— 手写
  转换变更编解码。
- `OriginalPartialEraseMutationCodec` —— 部分橡皮变更
  编解码。

## Harmony 决策

页级 op = 结构化 mutation 校验 + BinaryOp 编解码 —
— 对照原版各页操作（`de2.j`/`h85`/快照/书签/重排）。

## 产出

- fixture `d02-page-op-codecs.mjs`（10 断言）。
- ADR-1284；中文报告。
