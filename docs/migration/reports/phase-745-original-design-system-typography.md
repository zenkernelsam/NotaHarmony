# Phase 745 — 原版设计系统字体边界登记（ADR-0693）

日期：2026-09-25

## 结论

`res/font/` 审计收尾：原版字体分两体系 —— `qr4` 笔记内容
三族（Inter/Roboto/EBGaramond，开源许可，已移植）；`ar8`/`bv8`/
`taa` 设计系统四族（GT Flaire、Untitled Serif、Proxima Soft、
GT America Mono，**商业许可**）供 UI chrome 排版。四族商业
字体随 HAP 再分发无授权依据，登记为许可边界 fail-closed，
UI 以系统字体呈现（语义无损失）。

## 证据

- `ar8.java`：五槽位字体注册表（4 变体 Untitled Serif、3 变体
  Proxima Soft、GT Flaire 两档、GT America Mono Bold）。
- `bv8.java`：四族再导出为 MaterialTheme 排版槽位；
  `taa.java`：15 个 `zqe` TextStyle（34sp 付费墙 hero →
  12sp 等宽标签）。
- 消费面：`taa` 直连付费墙（`hye`/`u8j`/`e32`）、资料库卡片
  菜单（`gj9`）、Learn 测验（`jri`）；`bv8` 槽位遍布 149 处
  调用点（UI chrome 全局）。
- 详见 `docs/migration/evidence/original-design-system-typography-jadx-2026-09-25.md`。

## 验证

- 专项 Replay `d02-original-design-system-typography.mjs`：
  15/15 绿（ADR/证据 pin + NoteFonts 开源三族未波及断言）。
- 全量 Desktop Replay：629/629 fixture 绿。
- 无代码变更；双 HAP 复验通过。

## 备注

`res/` 资源域至此全部审计完毕：values 族（P734）、font（本
阶段）、xml/raw/anim/animator/interpolator/color/layout-watch/
values-watch 均为库内部或边界项。
