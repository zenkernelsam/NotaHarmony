# ADR-1261：应用入口 + Want 分流

## 状态

已接受（Phase 1317）。

## 决策

`MainActivity` intent/Startup → `UIAbility` onCreate+
Want 分流队列+onWindowStageCreate；widget→`Form
Ability`；配置→`FormEditAbility` —— 入口架构映射。

## 理由

`NoteAbility`（UIAbility：onCreate 入队 shared/launch/
deepLink/openTarget want+ThemeStore.init+onNewWant 热
启动+onWindowStageCreate→主题恢复+`loadContent`→
`pages/Index`）+4 Ability（主/备份/卡片）+2 卡片编辑
—— 入口+分流+主题降级架构。

## 后果

入口架构映射原版（intent→want 队列、widget→FormAbility）
—— 启动/分流语义保真。
