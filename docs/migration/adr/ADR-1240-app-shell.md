# ADR-1240：应用壳（Hilt+Startup+回退）

## 状态

已接受（Phase 1296）。

## 决策

Hilt DI → Harmony 手动 DI 容器；Startup Initializer →
`EntryAbility.onCreate` 初始化链；原生缺失 → `hilog`+
提示；升级 Receiver → `commonEvent` 监听。

## 理由

`NbApplication`(Application+fed Hilt)+`MainActivity`(r12
Compose)+`MissingNativeLibraryActivity`+`AppUpgrade
Receiver`+`initializers/*`(g06 Startup) —— 启动引导+
DI+容错架构。

## 后果

Harmony 应用壳 = EntryAbility+手动 DI+初始化链+容错 —
— 启动架构语义映射。
