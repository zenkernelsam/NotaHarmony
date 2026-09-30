# ADR-1099：a79 静态默认

## 状态

已接受（Phase 1155）。

## 决策

- `a79.N` = `apb.h(612,792)` = **US Letter 8.5×11 @72dpi**；
  `O` = `fsi.f(36×4)` = 0.5" margins；`P` = 792/8.5≈93.18；
  `Q` = nz9 默认背景；`R` = w69。
- 7 元数据 `w1b` LWW（title/defaultFont*/alignTextToLines/
  layoutMode/blockWrapSupport/handwritingLanguage）。
- `a79.a` = 27 参 copy-with mega。

## 依据

`apb.h(612,792)`/`fsi.f(36,…)`/`N.d()/8.5` + `fl6[] M` 7 属性。

## 后果

Harmony：默认页 = Letter 612×792、margins 36pt、dpi
93.18；元数据 7 LWW；copy-with 掩码。
