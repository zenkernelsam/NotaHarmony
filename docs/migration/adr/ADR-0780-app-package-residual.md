# ADR-0780 — `app/` 包残余面归档

- 状态：已接受
- 证据：`docs/migration/evidence/phase-836-app-package-residual.md`
- 回放：`docs/migration/replays/d02-app-package-residual.mjs`（12/12）

## 决定

1. androidx.startup 链（LoggingInitializer←AppStartup，依赖
   4 个 DataStore initializer）归档为启动排序证据——
   Harmony 无 androidx.startup 等价物，初始化顺序由
   NoteAbility.onCreate 显式编排（ADR-0772 已登记形态差）。
2. LoggingInitializer 的 GMS 证书 SecurityException 吞并
   为 vendor bug 规避——GMS 不存，不移植，登记。
3. `a2k` 登录门控 + 两 config activity 的
   `widget_*_login_required` 面——Harmony 卡片配置页
   （openFormEditAbility）自鉴权，模式差登记。

## 后果

`com/gingerlabs/notability/app/` 包全面闭合：入口链
（Application/Activity/receiver/provider/service/initializer/
config activity）无未解释成员。
