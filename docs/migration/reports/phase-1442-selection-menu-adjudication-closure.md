# Phase 1442 — 选择菜单轴终局裁决：剩余四项 fail-closed/死项坐实

## 范围

完成 `wqf`/`urf` 选择菜单轴最后四枚未裁决项的证据固化：
CONVERT_TO_MATH / CONVERT_TO_TEXT / SAVE_AS_STICKER / FIT_TO_PAGE。

## 原版证据

- `wqf.java` 23 枚枚举全映射（F..a0 字段 + ordinal）。
- `urf.java:266-470` 装配段：Q/R/T 各挂旗门或谓词；FIT_TO_PAGE
  枚举体 `wqfVar17` 从未赋静态字段（无 add 路径）。
- `h35.e0` = MATH_HANDWRITING_RECOGNITION td5 旗
  （`androidMathHandwritingRecognition` defaults=false）；
  `h35.z0` = STICKERS rd5 InternalUserOnly。
- `oim.b(mn7)` = `k != uo7.HIGHLIGHTER`（本地谓词，但分发链入 iink）。

## 裁决

四项全部 fail-closed/死项；Harmony `SelectionMenuAction` 无对应枚举、
分发无残留——**缺省即正确终态**，仅固化证据（overlay 注释升级 +
本报告 + ADR-1377）。wqf/urf 菜单轴 23 项至此全部裁决完毕。

## 验证

- `d02-selection-menu-adjudication-closure.mjs`：14/14。
- 全量基线 + `note@default` / `note@ohosTest`：见提交记录。
