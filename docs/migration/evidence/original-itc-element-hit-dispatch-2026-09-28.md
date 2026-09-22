# Evidence — itc 元素命中分派（dl1:317+）

- 日期：2026-09-28；Phase 621（修正 Phase 619 作用域）
- 来源：`decompiled_1.0.3/sources/defpackage/{dl1,itc,ftc,gtc,htc}.java`

## 类型层级（决定性）

```
itc.java:6   public final class itc implements ktc      // 单元素壳 — 非 htc
ftc.java:12  public final class ftc implements htc      // 多选壳
gtc.java:6   public final class gtc implements htc      // 组选壳
```

`htc` 携带 `a()`（未旋转选区矩形）与 `g()`（壳旋转角）——`yxi.e`
旋转矩形命中测试只对有 `htc` 接口的壳存在参数来源；`itc` 没有
这两个寄存器。

## dl1.java 分支结构

| 行 | 代码 | 语义 |
|---|---|---|
| 97 | `ktcVar instanceof htc` | htc 分支门（ftc/gtc） |
| 103-114 | `htcVar instanceof ftc` → `xtc.a(jE, set)`（白名单） → `yxi.e(cmb, j, ftc.d, fi3.b(cmb))` | deselectMode 白名单命中 + 旋转矩形内测 |
| 182 | `yxi.e(cmb, j, ftc.d, fi3.b(cmb))` | ftc 普通按下内测（旋转） |
| 212-232 | `yxi.e(cmbA, j, htc.g(), fi3.b(cmbA))`；非 gtc → `xtc.a(jE, null)` | htc 通用内测；ftc 非旋转时退回元素命中 |
| 267-286 | 同上（`htcVar.g()`，`gtc` 特例） | gtc 旋转内测 |
| **317-319** | `ktcVar instanceof itc` → `xtc.a(jE, null)` | **itc：直接元素命中测试，无矩形测试** |
| 320+ | 结果分派：`null`→`rtc`；`ntc`→`vtc`；`otc` 异 id→`vtc`；`otc` 同 id+文本→`ttc`；同 id 其他→`wtc` | id 相等经 `ba6.o(itcVar.a, hitId)` |
| 387 | `xtc.a(jE, null)`（etc/其余分支） | 同模式 |

## 语义结论

- **itc（单元素选区）**：按下「内部」≡ `xtc.a(jE, null)` 命中所选
  元素本身（真实几何 + 服务容差）。元素 AABB 内但几何外 →
  `rtc`/`vtc`（外部路径）。**无** `yxi.e` 调用。
- **ftc/gtc（多选/组选）**：按下「内部」= `yxi.e`——触点绕
  `fi3.b(htc.a())` 反旋转 `-d`/`-g()` 后对未旋转并集矩形
  `htc.a()` 做包含测试；`g()`/`d` 为 null（无壳旋转）等价 AABB。

## Harmony 对齐（NoteCanvasView.ets）

- `pointInSelectionRect(touch, canvasP)`：
  - 单元素选区（无组、总数=1）→
    `topmostPageElementIdAt(canvasP) === 所选 id`
    （`xtc.a` + `ba6.o` 等价；`topmostPageElementIdAt` 为
    `fu1.e`/`vnd` 等价服务：两程精确+5、真实几何含旋转）。
  - 多元素/组选区 → `uniformRotationUnrotatedScreenRect()`
    +反旋转点测试（`yxi.e` 等价）；null → `selectionRect` AABB。
- `uniformRotationUnrotatedScreenRect()`：全部选中非笔迹元素
  `rotationRadians` 恰为同一非零值时（≈壳旋转），逐元素克隆
  置 0 求未旋转 `bounds` 并集（≈`htc.a()`）；笔迹（旋转烘进
  点坐标）/旋转不一致/全零 → null（保守 AABB）。
- 四个调用点全部传 `canvasP`。

## 与 Phase 619 的关系

Phase 619 把 `yxi.e` 语义错用于单元素选区（itc）。本 Phase：
itc 改为元素命中（更精确，与原版同一路径）；`yxi.e` 泛化到
多元素/组选区（其真正作用域）。

## 验证

- `d02-original-itc-element-hit-dispatch.mjs`：17 断言全绿。
- `d02-original-rotated-selection-hit-test.mjs`（更新）：18 断言。
- `d02-original-selection-tap-clear` / `deselect-mode` /
  `text-surface-selection-dispatch`：调用点签名更新，全绿。
