# Phase 803 报告：字体资产面收口

日期：2026-09-23
Phase 类型：证据登记（无代码改动）

## 摘要

对原版 `res/font/` 做两版 diff 并按消费面分类，收口字体资产维度。
原版 7 族 17 文件，版本间唯一 delta 为已登记的 Inter 变量轴重命名
（opsz+wght → wght）。

## 分类结论

| 类别 | 族 | Harmony 状态 |
|------|----|--------------|
| 笔记文本选择器 | Inter / Roboto / EBGaramond | 已移植（`NoteFonts.ets` registerFont，ADR-0675） |
| 品牌 chrome 字 | ProximaSoft / UntitledSerif / GTFlaire / GTAmericaMono | 未移植——Compose 品牌字，主要承载面属后端绑定 fail-closed；其余以系统字体渲染，登记为视觉差异 |
| 供应商资产 | pdftron_exotic_font_resources.plugin（res/raw） | fail-closed（Phase 791） |

styles.xml 的 `sec-roboto-light`/`sec` 为三星主题属性，不属于应用字体面。

## 验证

- `d02-font-surface.mjs`：6/6 green
- 全量 Desktop Replay：见提交
- 双 HAP：default + note@ohosTest 成功

## 产物

- 证据：`docs/migration/evidence/phase-803-font-surface.md`
- Replay：`docs/migration/replays/d02-font-surface.mjs`
- ADR：`docs/migration/adr/ADR-0747-font-surface.md`
