# ADR-0737 — 原版 1.4.2 com.gingerlabs 包级全量归属

日期：2026-09-29
状态：已登记（包级差闭合；无源码变更）
证据：`docs/migration/evidence/phase-793-original-package-closure.md`
Replay：`docs/migration/replays/d02-original-package-closure.mjs`

## 背景

1.4.2 相对 1.0.3 新增 22 个 `com/gingerlabs` 包；逐包
核对类清单完成归属。

## 决策

- 22 包全部归属既有簇（日历/画廊/HWR/贴纸/模板/登录/
  工人/搜索/课程表/笔记上限）。
- 未功能性深挖的包均为薄实现（异常类/信号类/工人包装），
  其语义已在所属簇证据中记录。

## 后果

- 1.4.2 版本差证据面五维闭合：字符串（+722）/资源/资产/
  包/manifest。
- 后续 1.4.2 工作转入 Harmony 侧对齐实施与 T-042 窗口。
