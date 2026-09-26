# ADR-0747：字体资产面收口

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-803-font-surface.md`
- Replay：`docs/migration/replays/d02-font-surface.mjs`

## 决定

笔记文本字体面维持现状（3 族已移植）；品牌展示字体 4 族
（ProximaSoft/UntitledSerif/GTFlaire/GTAmericaMono）登记为
chrome-only 视觉差异，不移植。

## 依据

- 原版 `res/font/` 两版均 17 文件、7 族；版本间唯一 delta 为 Inter
  `opsz+wght`→`wght` 轴重命名（Phase 791 已登记）。
- 用户可见字体选择器仅 3 族（Inter/Roboto/EBGaramond，`qr4.c`），
  Harmony `NoteFonts.ets` 经 `registerFont` 完整实现（字重/斜体差异
  已记 ADR-0675）。
- 品牌 4 族为 Compose chrome 编程式引用，主要面（付费墙/gallery/引导）
  属 fail-closed 后端绑定；其余 chrome 文案 Harmony 以系统字体渲染，
  属风格差异而非功能缺口。
- styles.xml 中 `sec-roboto-light`/`sec` 为三星主题定制属性，与应用
  字体面无关。

## 影响

字体证据面关闭。文本编辑体验字体完整对齐；品牌视觉差异已显式登记。
