# ADR-1001 — Set× 包装族与胶带/peer/选区类型

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- Set× 包装族：SetString/SetBool/SetColor/SetFloat/
  SetPageBackground——"set-or-unset" 语义。
- `v01` Boundary{location:cxc, type}（xwd struct）=
  样式锚点。
- `ife` 9 胶带图案；`u76` 4 peer 工具（POINTER/PEN/
  HIGHLIGHTER/ERASER）；`qqe` TextSelection{anchor,focus}；
  `akb` RecordingAsset{metadata}。

## Harmony 决策

Set×→`Set<T>|unset` 联合；枚举 wire 对齐。

## Parity 状态

等价。

## 验证

- `d02-wrapper-types.mjs`：12/12 通过。
