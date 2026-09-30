# ADR-1100：Size/margins FlatBuffers 结构

## 状态

已接受（Phase 1156）。

## 决策

- `qed` = `core.flatbuffers.Size` `{w,h}` struct；
  `vy7` = 4-float margins/insets `{t,r,b,l}` struct。
- `apb.h(w,h)→qed`、`fsi.f(×4)→vy7` = FlatBuffers 结构
  写工厂（scratch builder→字段→校验→bind）。

## 依据

`qed/vy7 extends xwd implements ka4` + `a()→String` +
`apb.h`/`fsi.f` 工厂签名。

## 后果

Harmony：Size `{width,height}`、margins `{top,right,
bottom,left}` struct；工厂同构。
