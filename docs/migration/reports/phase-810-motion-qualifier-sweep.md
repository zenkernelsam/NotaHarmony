# Phase 810 — res/ 树全目录收敛(中文报告)

## 本阶段结论

`res/` 目录树完成全量版本对比，**资源层版本差异面闭合**。
本阶段处理最后两个未对比面：运动/着色资源与限定符目录。

## 运动与着色资源

| 目录 | 1.0.3→1.4.2 | 移除性质 |
|---|---|---|
| anim | 19→15 | 全为 AppCompat 弹窗动画 |
| animator | 9→7 | 全为 Material 按钮/Chip 状态动画 |
| color | 32→10 | 全为厂商着色状态列表 |
| interpolator | 7→7 | 无变化 |

存留中唯一应用级资源 `spen_recoil_*`(笔设置按钮按压回弹微动画)
两版共存，非版本差异。

## 限定符目录

- 12 个 `values-*` 目录、72 个文件对：应用级条目数零差异;
  `values-night/colors.xml` 逐字节一致。
- 目录级差异：移除 15 个 View 时代尺寸/朝向桶(经核查全部零应用
  内容),新增 2 个(hdpi 密度桶)。性质为 Compose 化后厂商
  限定符方案重构，无应用语义。

## 收敛状态

至此 `res/` 全部目录类型(strings/arrays/plurals/dimens/styles/
attrs/colors/font/raw/xml/drawable/layout/anim/animator/color/
interpolator/values-*)完成登记，含语义差异面已逐项处理，剩余
均为厂商裁剪。

## 验证

- Replay:`d02-motion-qualifier-sweep.mjs` 11/11;全量 683/683 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-810-motion-qualifier-sweep.md`
- `docs/migration/replays/d02-motion-qualifier-sweep.mjs`
- `docs/migration/adr/ADR-0754-motion-qualifier-sweep.md`
- 本报告
