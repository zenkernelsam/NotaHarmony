# Phase 621 — itc 元素命中分派（修正 yxi.e 作用域）

## 原版证据

- `itc.java:6`：`implements ktc`——单元素选区壳**不是** `htc`；
  `ftc.java:12`/`gtc.java:6` 才是 `htc` 实现，携 `a()` 未旋转
  矩形 + `g()` 壳旋转角。
- `dl1.java:97-286`：`htc` 分支（ftc/gtc）按下内测走
  `yxi.e(cmb, j, d/g(), fi3.b(cmb))`——触点绕未旋转矩形中心
  反旋转后包含测试；`g()` 为 null 等价 AABB。
- `dl1.java:317+`：`itc` 分支**不做选区矩形测试**——
  `xtcVar.a(jE, null)` 元素命中一次定分派：null→`rtc`（清除）、
  `ntc`→`vtc`（改选组）、`otc` 异 id→`vtc`、同 id 文本→`ttc`
  （进入编辑）、同 id 其他→`wtc`（拖拽）。

## 排查结论

Phase 619 误把 `yxi.e` 语义用于单元素选区（itc 不等价路径），
且多元素/组选区（yxi.e 真正作用域）仍退回 AABB。两处与
`dl1` 分支结构不一致：

1. 单元素选区内部判定应是**元素命中**而非矩形包含——元素
   AABB 内但几何外（椭圆角区）原版判外部。
2. 多元素/组选区若有统一壳旋转（旋转拖拽烘进各元素
   `rotationRadians`），应做未旋转并集测试而非 AABB。

## 修复

- `pointInSelectionRect(touch, canvasP)`：
  - 单元素（无组、总数=1）→ `topmostPageElementIdAt(canvasP)
    === 所选 id`（`xtc.a`+`ba6.o` 等价；该服务即 `fu1.e`/`vnd`
    等价：两程精确+5、`pointHitsShape`/`pointHitsAffineBlock`
    真实几何含旋转）。
  - 多元素/组 → `uniformRotationUnrotatedScreenRect()` 非空时
    反旋转点测试（`yxi.e` 等价），否则 `selectionRect` AABB。
- `uniformRotationUnrotatedScreenRect()`（619 helper 泛化）：
  全部选中非笔迹元素 `rotationRadians` 恰为同一非零值时，
  逐元素克隆置 0 求未旋转 `bounds` 并集→屏幕矩形；含笔迹
  （旋转烘进点不可还原）/旋转不一致/全零 → null。
- 四个调用点全部传 `canvasP`。

## 验证

- 新增 replay `d02-original-itc-element-hit-dispatch.mjs`：17/17 绿。
- 更新 `d02-original-rotated-selection-hit-test.mjs`（18/18）及
  tap-clear/deselect-mode/text-surface-dispatch 三个 fixture 的
  调用签名断言（均绿）。
- 全量 desktop replay 套件：511/511 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

Phase 621 commit（见 git log）。
