# ADR-1010：块 spec（ry0）+ 委托属性名册

## 状态

已接受（Phase 1066）。

## 决策

块实体 spec = `ry0`（`rl2` CREATE_BLOCK 物化），8 委托属性
rotation/scale/size/corner/textWrap/enableCaption/
positionLocked/zIndex（ULong）；`e4c` = 组成员集合。

## 依据

`fl6[] v` KProperty 名册保留属性名+类型签名；
`zIndex-tJoBMIg` 证实 ULong 值类；区别于 shape `m5d`/`ao2`。

## 后果

Harmony 块实体按此名册建寄存器；`e4c` 成员集合随实体。
