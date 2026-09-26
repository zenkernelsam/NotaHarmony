# Phase 813 — assets/ 内容级差异与 xxhdpi split(中文报告)

## 本阶段结论

`resources/assets/` 同路径文件内容差与 `config.xxhdpi.apk` 密度
split 成员差完成登记 —— 资源层对比在目录/文件名/键名/字节/值
五个粒度全部收敛。

## assets/ 指纹层

- 115 → 576 文件；新增 465 项全部归属已登记集群
  (papertemplates 446 / brushpacks 5 / covers 10 / planners 2 /
  spellcheck 2);移除 4 项 = MyScript lite 资源(794 已登记)。
- 同路径内容变化仅 5 项:
  - `conf/en_US.conf`:**`SetWordListSize 5→1`** —— MyScript
    手写识别候选词表收紧(语义调优，登记;Harmony 自研 HWR
    无对应参数);
  - `dexopt/baseline.prof{,m}`:基线 profile 重编译;
  - `dl-raw-content.res`、`math-sr.res`:MyScript 资源随引擎
    升级(与 811 .so size delta 互证)。

## xxhdpi 密度 split

47→51 项：移除 4 个 Holo 时代厂商选择器；新增 7 个厂商框架图 +
1 个应用资产 `ui_designsystem__academic_planner_onboarding.webp`
(学术规划册 onboarding 主图，Phase 782/792 面互证)。

## 验证

- Replay:`d02-assets-content-diff.mjs` 9/9;全量 686/686 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-813-assets-content-diff.md`
- `docs/migration/replays/d02-assets-content-diff.mjs`
- `docs/migration/adr/ADR-0757-assets-content-diff.md`
- 本报告
