# ADR-1101：Color/PageBackground 结构

## 状态

已接受（Phase 1157）。

## 决策

- `hu1` = `core.flatbuffers.Color` RGBA byte struct；
  `tu1` = float↔Color 打包门面 + `ra(13)` 懒默认。
- `nz9` = `core.flatbuffers.PageBackground` 表；
  `vv7.f`/`fag.k` = 背景构建。

## 依据

`hu1 extends xwd` byte×4 + `tu1.a/b/c` float↔int↔hu1 +
`nz9 extends cee`。

## 后果

Harmony：Color `{r,g,b,a:u8}` + float↔byte 打包 +
PageBackground `{color,size,pattern}`。
