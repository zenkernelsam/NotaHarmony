# ADR-1295：cubic-fitter 基线归属更正

## 状态

已接受（Phase 1354，更正 Phase 1326）。

## 决策

cubic-fitter 基线更正：`sqh`/`wy5` 实为 kotlinx-
serialization 多态注册器/Compose Modifier，非拟合
算法；真实基线待精确定位。

## 理由

实读源码：`qeh`=@interface 注解、`tdh`=注解工厂、
`sqh`=lm9/bx3 SerializersModule 链、`wy5`=ko3/nd8
Modifier —— 均非 cubic-fit。Harmony `CubicFitter`
（`fitCubic`/`maxError` 最小二乘+分段）实现本身正确，
误标仅在原版基线符号引用。

## 后果

更正基线归属；强化"基线引用须实读验证"规范。
