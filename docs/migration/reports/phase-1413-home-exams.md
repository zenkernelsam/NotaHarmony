# Phase 1413：Library Home "Upcoming exams" 分区 fail-closed 登记报告

- 日期：2026-10-01
- 状态：完成（fail-closed 判定；Desktop Replay 21 项本 Phase 检查 + 全量基线绿；无 `note/src` 变更）
- 证据：`docs/migration/evidence/phase-1413-home-exams.md`
- 决策：`docs/migration/adr/ADR-1349-home-exams-failclosed.md`

## 目标

沿 Phase 1412 补齐的 `vkm.a` Home 顺序继续推进：CTA → Coming up →
**Upcoming exams** → unindexed → favorites → recents。对 Exams 节
做出移植/不可移植判定并留档。

## 判定结论：fail-closed（数据结构层面无本地路径）

| 环节 | 证据 | 结论 |
|------|------|------|
| exam 标志来源 | `cbl.java:232` 设备事件恒 `zf1.F, k=null, l=false`；`jt1.java:1589` 仅 SYLLABUS 合流才置 `l=(g=="EXAM")` | 设备日历永远无法产出考试卡 |
| SYLLABUS 数据生产 | `uih`（`data.learn.syllabus` 服务端解析管道）→`ih4` `fl2→lhh`→`rgh` 写 Room `syllabusEvents`/`syllabusCourses` | Learn 后端特性，ADR-0652/0716 已 fail-closed |
| 卡模型生成 | `xy5` case1：`l==true` 且 `d∈[明日0点,+8天0点)`；`k`→`ymm.d`→`cpj`→`ip5.l`→`hp5` 课程文件夹解析，任一失败即丢弃 | 依赖 syllabusCourses↔文件夹颜色链 |
| 卡面操作 | `q8n.c` 文件夹 chip（`home_exam_open_folder`）；`acm.a`/`ig2` 主钮 = `aisparkle_med_bold`+`home_exam_review` Learn AI Review | 双后端依赖 |

## 本 Phase 产出

- 证据文档完整 decode：`vkm` 顺序位、`xy5` 7 天窗（不含今日）、
  `pij{a,b,c,d,e,f,g}` 字段、`q8n.b/c/e` 卡面三组件、`ig2` Review
  钮文案与图标、`rij` 非空才 emit 的缺省语义。
- ADR-1349：fail-closed 决定 + 复用条件（若未来 Learn/课表后端
  出现 Harmony 等价物，`xy5`/`pij`/`q8n` 规格可直接落地）。
- Replay `d02-original-home-exams-failclosed.mjs` 21 项：原版钉
  16 项（构造位/合流位/过滤窗/卡面/顺序/Review 钮）+ Harmony 钉
  5 项（无 exam 字串、无 Exams 渲染、无 syllabusEvents 等价、ADR
  与证据在档）。
- `note/src` 零变更；Coming Up 模型保留的 `source`/`isExam` 语义位
  按 ADR 空置登记。

## 与原版可观察行为的一致性

原版无课表数据时 `xy5` 产空 `arrayList6` → 不 emit `rij` → `q8n.e`
不渲染：Home 仅显示 Coming up。Harmony 现状（Phase 1412 后）与此
完全一致——用户可见差异为零；若原版用户导入过课表，其数据随
Learn 后端账号迁移而非本地迁移，新装/新平台本就不会出现考试卡。

## 验收核对

1. ✅ 原版证据：`decompiled_1.4.2` 七类硬钉（cbl/jt1/fch/ih4/uih/xy5/q8n/ig2/vkm）。
2. ✅ fail-closed ADR-1349 记录不可等价原因。
3. ✅ Replay 21 项新增；全量基线 1265/1265 绿。
4. ✅ 无 ArkTS 变更（静态检查基线不变）。
5. ✅ `note@default`/`note@ohosTest` 于 Phase 1412 同源码绿；
   本 Phase 仅 docs/replays。
6. ✅ 本报告 + 三份跟踪文档更新。
