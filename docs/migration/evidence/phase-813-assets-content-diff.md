# Phase 813 — assets/ 内容级差异与 xxhdpi 密度 split 收敛

## 目的

`resources/assets/` 的文件名级增量已在 Phase 761/762/763/792/794
登记(covers/brushpacks/papertemplates/planners/spellcheck/conf-lite)。
本阶段补完同路径文件的内容级 SHA-256 对比，以及
`config.xxhdpi.apk` 密度 split 的内容差异。

## 取证路径

- `decompiled_{1.0.3,1.4.2}/resources/assets/` 全树 SHA-256
- 两版 XAPK 内嵌 `config.xxhdpi.apk` 成员清单

## assets/ 总览

- 1.0.3:115 文件;1.4.2:576 文件。
- 新增 465 项，按目录分布:`papertemplates/` 446、`brushpacks/` 5、
  `covers/` 10、`planners/` 2、`spellcheck/` 2 —— **全部已在
  Phase 761(纸模板)、762(brushpack)、763(封面)、792(规划册/
  拼写检查词典)登记**。
- 移除 4 项:`conf-lite/` 与 3 个 `.lite.res` —— MyScript lite 引擎
  资源剔除(Phase 794 已登记)。

## 同路径内容变化(5 项)

| 文件 | 差异性质 |
|---|---|
| `conf/en_US.conf` | **语义调优**:`SetWordListSize 5` → `SetWordListSize 1`(两处)—— MyScript 手写识别候选词表大小收紧,识别候选收窄换取速度/简洁 |
| `dexopt/baseline.prof` | 基线 profile 重编译(Phase 794 面) |
| `dexopt/baseline.profm` | 同上 |
| `resources/document_layout/dl-raw-content.res` | MyScript 文档布局资源更新(随 811 的 MyScript .so 升级) |
| `resources/math/math-sr.res` | MyScript 数学资源更新(同上) |

## config.xxhdpi.apk split 差异

成员数 47 → 51:

- 移除 4 个 `abc_list_*_holo` —— Holo 时代 AppCompat 列表选择器
  (厂商裁剪，与 Phase 810 结论一致)。
- 新增 7 个厂商图(`notification_bg_*`/`notify_panel_*`/
  `tw_widget_progressbar_*` —— 通知与 TouchWiz 进度条框架图)。
- 新增 1 个应用资产:
  `res/drawable-xxhdpi-v4/ui_designsystem__academic_planner_onboarding.webp`
  —— **学术规划册引导页主图**,与 Phase 782/792 的 planner 面互证
  (1.4.2 新增的规划册 onboarding 素材)。

## 结论

assets/ 与密度 split 的内容级差异闭合：唯一语义层变化是
MyScript `SetWordListSize 5→1` 调优(登记,Harmony 自研 HWR
管线无对应参数，按调优意图理解即可)与规划册 onboarding 图新增;
其余为厂商裁剪与引擎资源跟随升级。
