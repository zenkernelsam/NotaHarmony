# ADR-1028：块含成员集合（m4c）

## 状态

已接受（Phase 1084）。

## 决策

Harmony 块实体可持 `m4c` 成员集合（嵌套子项树）：

- `cie` 文本块（`ry0`+`m4c`+`vy7`）；
- `hp5` 媒体块（`ry0`+`m4c`+`dp5`+caption）。
- `m4c` = 集合 spec（margins/纵横比/子项列表/`l4c`/`bxc`/
  `hja`/`cl2`）+ `D` copy-with。

## 依据

`cie`/`hp5` 的 `m4c` 字段 + `bf0` spec 标记。

## 后果

Harmony 块树经 `m4c` 嵌套；`M()` 父集合解析回溯。
