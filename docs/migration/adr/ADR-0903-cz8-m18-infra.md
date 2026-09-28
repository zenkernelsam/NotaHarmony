# ADR-0903 — 基础设施三件：`cz8`/`x82.x`/`m18`

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `cz8 extends ThreadLocal` = 复位式线程局部池
  （`initialValue`=工厂，`get`=取+复位λ）——sg5/dk4 池基底。
- `x82.x` = Kotlin 属性委托 getValue（a()+b.invoke 两步）。
- `m18.S/E` = Kotlin ListBuilder 建/封（th7(10)+K=true+空→L）；
  `y0`=round+NaN 护栏；`x82.A/z/y`=UTF-8→UTF-16（代理对公式实证）。

## Harmony 决策

ThreadLocal 池在 ArkTS 无需（无共享可变缓冲更稳）；
buildList→数组+Object.freeze 等价；UTF-8 语义等价。

## Parity 状态

等价。

## 验证

- `d02-cz8-m18-infra.mjs`：14/14 通过。
- 全量 Replay 832 文件绿，见 Phase 959 提交。
