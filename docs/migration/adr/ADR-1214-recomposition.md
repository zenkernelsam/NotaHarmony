# ADR-1214：Compose 重组引擎

## 状态

已接受（Phase 1270）。

## 决策

`uz4`/`r42`/`sh8`/`fsi` 重组引擎 → Harmony `@Component`+
`@State`/`@Builder`+组件成员缓存。

## 理由

`uz4`=Composer（`tz4` SlotTable+`kgd/lgd/ogd` reader/
writer+`oha` remember-holder）；`r42.a`=`sh8(20)`=
Composer.Empty 哨兵；`fsi.T`=remember —— 声明式重组
+槽表缓存核心。

## 后果

Harmony 声明式重组 = @Component+@State+@Builder —
— `remember`→组件成员；重组语义保真。
