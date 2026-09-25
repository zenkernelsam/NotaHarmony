# ADR-0693：原版设计系统字体（ar8/bv8/taa）许可边界 fail-closed

- 状态：Accepted
- 日期：2026-09-25
- 证据：`docs/migration/evidence/original-design-system-typography-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-design-system-typography.mjs`

## 背景

原版 `ar8` 注册五族设计系统字体（GT Flaire Black/Extra、
Untitled Serif 四变体、Proxima Soft 三变体、GT America Mono
Bold），经 `bv8` 主题槽位 + `taa` 的 15 个 `zqe` TextStyle
供 UI chrome 全局消费（付费墙、资料库卡片菜单、Learn、权限
页等）。与 `qr4` 笔记内容字体（Inter/Roboto/EBGaramond，开源
许可，已移植，ADR-0675）是独立的两套体系。

## 决定

设计系统四族**不随 Harmony HAP 再分发**：GT Flaire（Grilli
Type）、Untitled Serif（Klim）、Proxima Soft（Mark Simonson）、
GT America Mono（Grilli）均为商业许可字库，APK 内打包属原版
授权，提取再分发不具备同等授权依据。Harmony UI chrome 以系统
字体呈现全部文案与层级（字号/字重/颜色语义保留）。

## 影响

- 无代码变更（边界登记）。
- 视觉差异：标题展示字由 GT Flaire 换为系统字；正文衬线由
  Untitled Serif 换为系统字；等宽标签由 GT America Mono 换为
  系统等宽 —— 纯字形差异，无行为/语义差异。
- 付费墙/Learn 等消费面本身已 fail-closed（ADR-0662/0652），
  实际可感差异集中在资料库卡片菜单等少数场景。

## 备选方案及否决理由

- 拷贝字体进 rawfile + registerFont：技术上可行，许可上不可行
  （商业字库再分发）。否决。
- 寻找近似开源替代（如 Libre Caslon ≈ Untitled Serif）：引入
  新的第三方资产与视觉误差，收益低。否决，维持系统字体。
