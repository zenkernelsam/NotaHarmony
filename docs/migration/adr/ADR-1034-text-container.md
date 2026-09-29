# ADR-1034：e4c 文本容器（修正 1066）

## 状态

已接受（Phase 1090）。

## 决策

`e4c implements o4c` = **文本块内容容器**（非组集合）：
`exc` 锚点序列 + UTF-8 `CharsetDecoder` 流式解码 +
`s3c`/`hr5`/`swc` 片段类型 + `m4c.D` 物化 copy。

## 依据

`e4c` 持 24 处 `exc` 引用 + UTF-8 REPORT 解码器 +
8192-char 缓冲。

## 后果

Harmony 文本以 UTF-8 流 + exc 锚点序列存；非法字节
REPORT（严格，非静默）。
