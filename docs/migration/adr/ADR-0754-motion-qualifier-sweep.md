# ADR-0754 — res/ 树全目录收敛(运动资源 + 限定符重构)

- 状态：Accepted
- 日期：2026-09-21
- 关联：ADR-0749~0753(values 各面)、Phase 791/793(厂商裁剪)

## 背景

`res/` 树中 anim/animator/color/interpolator 运动与着色资源及
全部 `values-*` 限定符目录是最后未逐类对比的资源面。

## 取证结论

- anim 19→15、animator 9→7、color 32→10、interpolator 7→7:
  移除项命名全为 `abc_`/`mtrl_`/`material_`/`design_`/`switch_`/
  `fragment_` 等厂商前缀，无应用语义。
- 存留的唯一应用级运动资源为 `spen_recoil_*` 三项(笔设置按钮
  按压回弹微动画),两版共存，非差异。
- 12 个 `values-*` 限定符目录逐文件扫描应用级前缀
  (`feature_|ui_|app_|pen_`)条目数：72 个文件对零差异;
  `values-night/colors.xml` 逐字节一致。
- 目录级差异：移除 15 个 View 时代限定符桶(color-night/
  layout-land/layout-watch/12 个 values-* 尺寸朝向桶),
  全部经核查含零应用级条目；新增 2 个(`drawable-hdpi`、
  `values-hdpi`)。性质为 Compose 化后厂商限定符方案重构，
  不含应用语义。

## 决策

1. 运动/着色资源移除登记为厂商裁剪，不移植、不补偿。
2. `spen_recoil_*` 作为 SPen 按压微动画证据登记,Harmony 的
   笔设置面以 `pressEffect`/动画曲线自行表达(语义等价，非
   资源级复制)。
3. 限定符目录重构登记为打包层差异；Harmony 资源限定符体系
   (dark/横竖屏/车机)由 module.json5 与资源目录名自治，不做
   目录级对齐。

## 后果

`res/` 整树收敛：所有目录类型完成版本对比，含语义差异面
(strings/arrays/plurals/font/raw/xml/drawable)此前已逐项登记,
剩余差异均属厂商裁剪与打包重构。
Replay `d02-motion-qualifier-sweep.mjs` 11/11 钉住。
