# ADR-0590 — itc 元素命中分派（修正 yxi.e 作用域）

- 状态：Accepted（修正 ADR-0588 的作用域）
- Phase 621；对齐 `dl1.java:317+` itc 分支 + `itc`/`htc` 类型层级
  （decompiled_1.0.3）。

## 背景

Phase 619 按 `yxi.e` 语义为「单个旋转元素选区」实现了反旋转矩形
命中测试。后续精解 `dl1.java` 的完整分支结构发现作用域错误：

- `itc.java` `implements ktc` —— **不是** `htc`。`htc` 由
  `ftc`（多选）/`gtc`（组选）实现，携 `a()` 未旋转矩形 + `g()`
  壳旋转角。
- `dl1.java:114/182`：仅 `htc` 分支（ftc/gtc）调用
  `yxi.e(cmb, j, g(), center)`。
- `dl1.java:317+`：`itc` 分支**不做任何选区矩形测试**——
  `ptcVarA4 = xtcVar.a(jE, null)` 对全部元素做一次命中测试，
  按命中结果分派：
  - `null` → `rtc`（清除选区）
  - `ntc`（组成员）→ `vtc`（改选组）
  - `otc` 异 id → `vtc`（改选他元素）
  - `otc` 同 id + 文本类 → `ttc`（进入文本编辑）
  - `otc` 同 id + 其他 → `wtc`（拖拽）

即 itc 的「内部」≡ 命中所选元素的**真实几何**——元素 AABB 内
但几何外（椭圆角区、旋转形状边角）原版判为外部。

## 决策

1. `pointInSelectionRect(touch, canvasP)` 新增签名参数 `canvasP`，
   分两层：
   - **单元素选区**（无选中组且总数=1，itc 等价）：
     `topmostPageElementIdAt(canvasP) === 所选 id`——元素命中测试
     即内部判定（`xtc.a(jE,null)` + `ba6.o(itcVar.a, hit)` 等价）。
     命中他元素/空由既有外侧探针路径完成 `vtc`/`rtc`。
   - **多元素/组选区**（ftc/gtc 等价）：保持 `yxi.e` 路径——
     `uniformRotationUnrotatedScreenRect()`（原
     `singleSelectedUnrotatedScreenRect` 泛化）+ 反旋转点测试。
2. `uniformRotationUnrotatedScreenRect()`：对全部选中非笔迹元素
   取 `rotationRadians` 集合，仅当集合恰为单一非零值（≈壳旋转角，
   旋转拖拽把角度烘进各元素）时，逐元素克隆置 0 求未旋转
   `bounds` 并集（≈`ftc.a`/`htc.a()`）转屏幕矩形；
   含笔迹（旋转烘进点坐标不可还原）、成员旋转不一致或全为 0
   → null 退回 `selectionRect` AABB。
   - `PolygonElement` 等非 `rotationRadians` 载体按 0 计入——
     与「不同初始旋转成员组成的选区 `ftc.d` 为 null → AABB」
     的原版语义一致。
3. 四个调用点（deselectMode 外测×2、菜单门×1、inside 拖拽门×1）
   全部传入 `canvasP`。

## 边界 / fail-closed

- `topmostPageElementIdAt` 即 `fu1.e`/`vnd` 等价服务：两程精确
  +5 页单位容差，`pointHitsShape`/`pointHitsAffineBlock` 为真实
  几何（含旋转）。对单元素选区，「内部」判定与原版同为
  元素命中——比 Phase 619 的矩形测试更精确。
- 含笔迹的多元素旋转选区退回 AABB（保守超集）——原版壳旋转
  寄存器在 Harmony 模型中无对应；已在本 ADR 与 fixture 注释
  注册。
- deselectMode 两个调用点属 `ftc.h` 语境，单元素分支不会触发
  （itc 无 deselectMode），统一函数安全。

## 证据

- `docs/migration/evidence/original-itc-element-hit-dispatch-2026-09-28.md`
- Replay：`d02-original-itc-element-hit-dispatch.mjs`（17 断言）
- `d02-original-rotated-selection-hit-test.mjs` 更新为泛化版
  （18 断言）
