# Phase 676 报告：真机验收清单补遗刷新

## 摘要

按 ADR-0542 维护规则（新“仅真机可验”项必须同步登记），对
Phase 571 验收清单做第二次补遗：复查 ADR-0572~0642，提取 13 项
桌面 replay + HAP 构建无法覆盖的运行态事项，追加“十一、
Phase 676 补遗”节。清单规模 41 + 15 + 13 = 69 行。

## 登记项

- 手写/画布：touch slop 8px 常量（ADR-0580）、文本面笔压制与
  桶键缺失（ADR-0572）、选中组邻居 z-order（ADR-0594）。
- 图片：拖放入口手感与多记录类型（ADR-0599）。
- 页面：页总览批量 Clear 假设（ADR-0618）。
- 导入导出/分享：四格式导入 picker（ADR-0619~0622）、外部分享
  PDF 权限窗口（ADR-0628）、systemShare 多文件交付与 syscap
  （ADR-0641）。
- 系统交互：note 深链（ADR-0631）、三卡片 formAbility
  （ADR-0632）、open-target extras（ADR-0633）、库内多选手势
  （ADR-0640）。

剔除：纯样板“未启动设备”声明（ADR-0612~0614 等）与桌面可验项
（ADR-0642 ruler_units 偏好行）。

## 改动文件

- `docs/migration/audit-2026-08/真机验收清单-2026-09-22.md`：
  新增第十一节 13 行 + 抬头时间范围更正。
- `docs/migration/evidence/device-verification-checklist-harmony-2026-09-22.md`：
  追加 Phase 676 刷新记录。
- `docs/migration/replays/d02-device-verification-checklist.mjs`：
  行数下限 40→68 + 15 个新 ADR 锚点 + 节断言。
- `docs/migration/adr/ADR-0643-device-verification-checklist-refresh-676.md`：本 ADR。

## 验证

- fixture：137/137。
- 全量 Desktop Replay：560/560。
- `note@ohosTest` clean + `note@default` HAP 构建成功（无源码
  改动，构建为基线复验）。
- 无模拟器/真机/Hypium 验证（本表即为其前置准备）。

## 后续

- 首个真机/模拟器日按清单 69 行逐项验收并回填结果列。
- 后续 Phase 新增仅真机可验项时继续同步登记。
