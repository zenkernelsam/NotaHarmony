# ADR-1012：实体生命周期 = spec→live 对称

## 状态

已接受（Phase 1068）。

## 决策

Harmony 实体统一 spec→live：

- Shape：`ao2`→`n5d`(spec)→`m5d`(14-reg live)
- Block：`rl2`→`ry0`(spec)→`qy0`(12-reg live)

spec 持 `yc6` 快照，live 持 `fqb` builder（`do6.g` 桥）；
`be5`/`fi0` 统一变换面；块只委托 3 变换属性。

## 依据

`qy0`/`m5d` 同构 ctor + 寄存器数组 + KProperty 名册。

## 后果

Harmony 每实体类 = spec + live + payload 三件套；
寄存器写合并语义统一。
