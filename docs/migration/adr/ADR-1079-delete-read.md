# ADR-1079：e4c 删除态/快照/批量读

## 状态

已接受（Phase 1135）。

## 决策

- `A(Integer)` = 位置→cursor→锚→tombstone Boolean
  （"该位字符是否已删"）。
- `a()→m4c` = live→spec 重建（l4c + bxc + hja + cl2）。
- `f(List)` = `runBlocking` + 200ms 超时批量应用。
- `h` = 静态抽取→`s3c`；`c()`=总数；`d()`=`or5` 引擎。

## 依据

`au1.g1(pos,e.g)`→`xj2.f(exc,g.I)`；`m4c.D(...,4225)`；
`x90.J0(…200ms…)`。

## 后果

Harmony：删除检查三步链；spec 快照同构；批量 async
超时（200ms 语义保）。
