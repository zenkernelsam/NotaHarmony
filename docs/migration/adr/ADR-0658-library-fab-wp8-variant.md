# ADR-0658 — 库 FAB chip `wp8` 按钮变体

## 状态
已接受（Phase 1366）。

## 背景
原版 `cd` case 0：`wp8.I`(FILLED) 用于 Create Note（末位主操作），
`wp8.J`(TINTED) 用于 Import/Templates/DocScan。`wp8` 枚举
FILLED/TINTED/STROKE/PLAIN。Harmony 此前无主次区分。

## 决定
`CreateActionChip` 加 `emphasized`：FILLED→`accent`+`onAccent`+白描边
`fab_createnote_filled.svg`；TINTED→`surface`+`textPrimary`。Create Note
传 emphasized=true，其余默认 TINTED。

## 后果
FAB 末位 Create Note 呈现 accent 填充强调，与其余 tonal chip 区分，符合原版。

## 验证
`d02-library-fab-order.mjs` 25/25。
