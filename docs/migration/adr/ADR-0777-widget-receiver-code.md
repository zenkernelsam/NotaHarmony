# ADR-0777 — Receiver/Widget 代码语义归档

- 状态：已接受
- 证据：`docs/migration/evidence/phase-833-widget-receiver-code.md`
- 回放：`docs/migration/replays/d02-widget-receiver-code.mjs`（15/15）

## 决定

1. **AppUpgradeReceiver 语义更正**：系 androidx.profileinstaller
   的 Baseline Profile 重写（`tid.b` + 文件锁守卫 + goAsync），
   非通用缓存失效。Harmony 无应用级 profile 刷新义务
   （系统 AOT 管理）——不移植，登记。
2. **Widget 数据模型**：`hng(label + CREATE_NOTE/VIEW intent +
   绑定集合)` 与 Harmony `formBindingData` 推送 + 
   `openFormEditAbility` 双配置页对齐——**已等价**。
3. **WidgetImageProvider 语义**：双路径类（thumbnail/text）
   + 48dp 圆角 + `?f=` 回退 + FileNotFound fail-closed；
   Harmony 经 formProvider 数据通道推送位图——模式差登记。

## 后果

manifest 组件层的代码语义全部闭合：升级接收器、5 widget
provider、2 个授权 provider 的可执行语义均有对照记录。
