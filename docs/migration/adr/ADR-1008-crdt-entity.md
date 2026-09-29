# ADR-1008：CRDT 实体 = spec + 寄存器数组

## 状态

已接受（Phase 1064）。

## 决策

Harmony 可变换实体采用 `n5d`/`m5d` 分离：

- `n5d` spec：每属性一个 `yc6` 默认寄存器快照（声明式模式）；
- `m5d` 实体：14 `fqb` LWW 寄存器 + 访问器映射
  （o→c/n→d/w→e/J→f）+ `be5` 读 `.b` materialize；
- `ei0` 绑定属性引用寻址寄存器。

## 依据

`fi0`/`k5d` iface + `m5d` 14 寄存器 + `do6.g` 快照初始化——
写入（Phase 1062/1063）与读取分离，spec→实体工厂化。

## 后果

Harmony 实体持 `LWWRegister[]`；属性经委托读寄存器（非裸
字段），保证所有变更过 CRDT merge 路径。
