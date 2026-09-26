# ADR-0797：Room DDL 语句级登记与 Harmony 单库归并确认

## 状态

已接受（2026-09-23，Phase 853）

## 背景

Phase 822 在"库×版本×实体"粒度闭合数据库拓扑；语句级 DDL
（CREATE TABLE/INDEX 原文、迁移体重建模式）尚未登记。
反编译产物中应用 DDL 不在 `*_Impl` 壳内，而在 R8 合并后的
代理类 `defpackage/ca3` + 5 个迁移体（wf1/yf1/r4a/zmb/fgf）。

## 决定

以 `ca3` + 迁移体为准登记原版全部语句级 DDL：
54 应用表 + 7 WorkManager/vendor 表 + 18 CREATE INDEX；
迁移体中 `_new_*` 重建模式证明 Calendar/Learn/Search/
Toolbox/RawLibraryState 各库在版本间经历列级变更。

Harmony 单库 RDB（`DatabaseHelper.ets`，88 语句 / 67 表）
对原版本地域全覆盖；以下原版表域在 Harmony 无对应，
维持 fail-closed（与功能域登记一致，非新增缺口）：

- Learn 学习域 7 表（QuizSession/QuizOp/…）
- Calendar 4 表（calendarSelections/syllabus*）
- GalleryMutation 2 表（PendingLike/PendingFollow）
- Transcription 2 表（transcriptions/…segments）
- WorkManager/Firebase/Mixpanel/Intercom/DataTransport
  vendor DDL（平台无此依赖）

## 依据

- `decompiled_1.4.2/sources/defpackage/{ca3,wf1,yf1,r4a,zmb,
  fgf,s4a}.java`（应用 DDL + 迁移体）
- `defpackage/{xbf,oal,cye,ao9,ac3}.java`（vendor DDL 隔离）
- `note/src/main/ets/data/DatabaseHelper.ets`（Harmony RDB）

## 后果

- Replay `d02-room-ddl-registry.mjs`：36 项断言。
- Room DDL 面闭合；数据库证据链 拓扑(822) → 语句(853) 两级完整。
