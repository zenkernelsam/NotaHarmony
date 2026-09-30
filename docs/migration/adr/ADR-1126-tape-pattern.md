# ADR-1126：TapePattern 枚举（washi-tape）

## 状态

已接受（Phase 1182）。

## 决策

`ife`=`TapePattern` 9 值枚举 **直接保留** —
`STRIPES/GRID/DOTS/PLAIN/STARS/FLOWERS/HEARTS/WAVES/
CHECKERS`（对齐 `core.flatbuffers.TapePattern` schema +
`n5d.tapePattern`）；`mwd` 纸胶带笔画按图案纹理填充
→ Harmony `ImagePattern`/`PixelMap`。

## 理由

`ife` 枚举恢复出 9 名+byte 序+`nz3` holder；`mwd` 持
`ife`。

## 后果

纸胶带工具 = InkStyle 笔画 + 9 图案填充；Harmony 图案
纹理渲染；schema 4-值全保留。
