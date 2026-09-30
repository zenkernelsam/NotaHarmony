# ADR-1131：a76 int-rect + r93 Density

## 状态

已接受（Phase 1187）。

## 决策

- `a76` int-rect `{l,t,r,b}` + long 打包访问器（中心/
  尺寸/左上）→ Harmony `common2d.Rect` + 打包 helpers。
- `r93` `Density` iface（dp↔px 换算，`cl3` long 拆包 +
  `floatToRawIntBits`）→ Harmony `vp2px`/`px2vp`
  （`UIContext`/`display`）。

## 理由

`{int×4}` + `<<32`/`0xffffffff` 打包 + `f()=c-a`/`c()=d-b`
+ `r93` `B/C0/j0` + `floatToRawIntBits`。

## 后果

视口几何：int rect bounds + 打包点/尺寸 helpers +
Density dp↔px —— `ViewportState` rect/density 字段对齐。
