# ADR-0685: app/initializers 尾项 + 高对比度文字 a11y 边界登记

- 状态：已接受（收口登记 + a11y 边界 fail-closed）
- 日期：2026-09-25
- 阶段：Phase 737
- 证据：`docs/migration/evidence/original-initializers-hct-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-initializers-hct.mjs`

## 背景

继 Phase 736（NbApplication.onCreate）之后，本 ADR 关闭
androidx.startup 的 `g06` Initializer 入口与 `app/` 包末组件
`MissingNativeLibraryActivity`。审计中发现一条此前未登记的
**无障碍管线**：原版把 Android `high_text_contrast_enabled`
系统设置接入墨迹渲染。

## 逐项决策

1. **高对比度文字（HCT）管线：平台边界 fail-closed**。
   - 原版链路：`je5` ContentObserver 盯
     `Settings.Secure high_text_contrast_enabled` → `ke5.a`
     原子标志 → `ie5.a(bitmap)` 工厂返回 `bh5`（HCT 适配
     Canvas 子类）→ `vw7` 渲染分支参与判定。
   - HarmonyOS `@ohos.accessibility` 公开 API 不含 HCT 查询
     （只有 accessibility/touchGuide/screenReader/touchMode/
     captions），亦无墨迹层 Canvas 文字剥离机制。
   - 处置：登记 fail-closed。Harmony 侧不订阅设置变更、不引入
     HCT 分支；若未来系统开放该查询，应在此管线原语义上补接。
2. **Rive 原生库 init + MissingNativeLibraryActivity：边界**。
   Rive 运行时不随 Harmony 打包（ADR-0663 系列），不存在 .so
   缺失态；兜底 AlertDialog Activity 无对应物。
3. **backend_override 后门：内部测试通道 fail-closed**。
   `LoggingInitializer` 读 `SharedPreferences "backend_override"`
   url 键覆盖后端环境 —— 面向内部的调试后门，不移植。
4. **其余初始化项**：`is1.j0` 静态注入、`ec4`/`q36`/`iw2`/`hw2`
   datastore/流装配、`v50`/`h6g` DI 协程、`sl` SDK-35 条件
   初始化、startup `dependencies()` —— 内部管线/平台机制，
   无独立用户可话语义。

## Harmony 侧对应

- 无新增代码：全部为登记项。
- `NoteAbility.onCreate` 的既有启动序列（ThemeStore→loadMainContent）
  已覆盖可移植启动语义；HCT 边界解除时可经
  `accessibility.on` 事件族接线。

## 边界与限制

- `bh5` 绘制改写逻辑在原生 Canvas 层，JADX 空体 —— 观感差异
  未复现、不可复现（无 API）。
- `sl` SDK-35 分支为协程合成类，具体任务未展开。
- 未做模拟器/真机/Hypium 验证。
