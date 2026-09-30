# ADR-1165：IME/软键盘层

## 状态

已接受（Phase 1221）。

## 决策

`eje` 软键盘 Modifier.Node（`qie` 会话 + `q52`
选择联动 + `m`/`q` 几何）+ `k6f` 会话持有 +
`yie`/`yla` 平台控制 → Harmony `inputMethod` 模块
（show/hide + `@Watch` 可见性 + `UIContext`）。

## 理由

`eje extends n73 implements q52,qie` + `c0` Job +
`k6f.a`→`rad` 协程 + `yie` 经 `aa6.v(eje,zie.b)`
令牌查找 + `yla` Context+SharedFlow —— Compose
PlatformTextInput/TextInputSession 体系。

## 后果

Harmony 软键盘 = inputMethod 服务 + 节点会话 +
可见性流 —— 显隐时序对齐。
