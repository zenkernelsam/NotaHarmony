# ADR-1092：s06 payload 部

## 状态

已接受（Phase 1148）。

## 决策

- `s06` payload = `pp7`(nr5 布局包装) + `dm2`(FlatBuffers
  payload 表) + `d16`(6-reg 快照集) + `u16`(kind 字节
  enum) + `z4`。
- `dm2` 字段读：`A`float/`C`fqa/`a`String/`j`mmf/`k,n`hu1。

## 依据

`pp7{nr5}` + `dm2 extends cee` + `d16{yc6×6}` + `u16{byte}`。

## 后果

Harmony：payload = 表读 + reg 快照 + 布局包装 + kind
enum —— `s06` 全字段可序列化复刻。
