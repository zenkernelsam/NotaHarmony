# ADR-0757 — assets/ 内容级差异与 xxhdpi split 收敛

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0726(covers/planners)、Phase 761/762/763/792/794
  (assets 增量面)、ADR-0755(.so 清单)

## 背景

assets/ 的目录级增量已登记;同路径文件的内容级(SHA-256)差异与
`config.xxhdpi.apk` 密度 split 的成员级差异为最后未登记资源层。

## 取证结论

- assets/ 115→576;新增 465 项全部落入已登记集群
  (papertemplates 446、brushpacks 5、covers 10、planners 2、
  spellcheck 2);移除 4 项为 MyScript lite 资源(794)。
- 同路径内容变化仅 5 项:`conf/en_US.conf` 的
  `SetWordListSize 5→1`(MyScript 识别候选词表调优)、
  `dexopt/baseline.prof{,m}` 重编译、MyScript `dl-raw-content.res`
  与 `math-sr.res` 跟随引擎升级。
- `config.xxhdpi.apk` 47→51 项：移除 4 个 Holo 厂商选择器；
  新增 7 个厂商框架图与 1 个应用资产
  `ui_designsystem__academic_planner_onboarding.webp`
  (学术规划册 onboarding 主图)。

## 决策

1. **MyScript `SetWordListSize 5→1`** 登记为原版识别调优参数:
   候选词表从 5 收紧至 1。Harmony 手写转换为自研管线，无同名
   参数，不调表调优；仅登记语义以便日后调参参考。
2. **规划册 onboarding 图**登记为 1.4.2 新素材，归属
   Phase 782/792 规划册面；Harmony 无该界面,fail-closed。
3. **厂商项**(Holo 选择器移除、通知/进度条框架图新增)登记为
   厂商裁剪/重构，无语义。

## 后果

- assets/ 与密度 split 的内容级差异闭合；资源层对比至此在
  目录、文件名、键名、字节、值五个粒度全部收敛。
- Replay `d02-assets-content-diff.mjs` 9/9 钉住。
