# 原版证据：覆盖层内元素级 ttc 产出（itc/gtc 分支）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 593 依据。

## 1. 三种选区状态

`dl1` 的 pointer-down 按 `htc` 子类型分流：

- `itc`：单元素选区（`itc.a` = 唯一选中元素 id）。
- `ftc`：多元素选区（`ftc.h`=deselectMode、`ftc.i`=deselectedIds）。
- `gtc`：组选区（`gtc.b` = 组成员 id 集、`gtc.d` = 覆盖层矩形）。

## 2. 覆盖层内按下（`yxi.e(cmb,jE,…)` 命中）

### `itc` 分支（`dl1.java:265-281` 同族代码段；另见 320-330）

```java
ptcVarA4 = xtcVar.a(jE, null);
… else if (ptcVarA4 instanceof otc) {
    vnd vndVar2 = ((otc) ptcVarA4).a;
    ly3 ly3Var2 = vndVar2.I;
    if (!ba6.o(itcVar.a, ly3Var2.getId())) {
        ttcVar = new vtc(ptcVarA4);          // 命中非选中元素 → TapToSelect
    } else if (!z2 || ufbVar.I.getValue() == null) {
        ttcVar = ly3Var2 instanceof xhe
            ? new ttc(ly3Var2.getId(), jE)    // 文本块 → 元素级 ttc
            : new wtc(ys2.x(vnd.b(vndVar2)), itcVar);   // 非文本 → 拖
    } else { ttcVar = utcVar; }
}
```

### `gtc` 分支（`dl1.java:213-227`）

```java
vndVarE = xtcVar.c.e(jE, fvbVar.c(), null);   // 点下最上层元素
ly3Var = vndVarE != null ? vndVarE.I : null;
if ((ly3Var instanceof xhe) || !((gtc) htcVar).b.contains(vndVarE.I.getId())) {
    ttcVar = new wtc(((gtc) htcVar).d, htcVar);   // 文本成员/非成员 → 拖整组
} else {
    ttcVar = new ttc(vndVarE.I.getId(), jE);       // 非文本成员 → ttc
}
```

### `ftc` 分支

覆盖层内按下 → 无条件 `wtc`（整体拖拽，Phase 590 已对齐）。

## 3. `xhe` = 文本块实体标记

- `xhe.java`：`interface xhe extends oy0, be5, ce5`。
- `cie.java`：唯一实现——`paper`、`resizesWidthToFitText` 属性寄存器，
  即 TextBlock 实体。

## 4. `ttc` → `qke`（`uw2.java` case4 + `uke.java:258-268`）

```java
xtcVar2.d(new qke(ttcVar.a), true, z);   // qke = "TextBlock(id)"
// uke.d case：
ake akeVar2 = (ake) ukeVar2.p.get(((qke) rkeVar).a());  // 激活文本块编辑器
if (akeVar2 == null) → "Cannot activate text editor, not found" 日志
```

- `qke` 对文本块 id → 激活编辑表面（`ake`）；对非文本 id → 查找失败
  → 仅日志，实际 no-op。
- `uw2` case4 随后对*当前活动*文本块跑 `rej.i` 链接命中（Phase 592）。

## 5. Harmony 对齐（Phase 593）

覆盖层内按下（`isSelectionActive` + `selectionVisible` + `pointInRect`）：

| 原版 | Harmony |
|---|---|
| `itc` 命中同一 `xhe` 文本块 → `ttc` → `qke` 激活 + 链接探测 | 单文本块选区命中同块 → `linkHitOnTextBlock`（链接→菜单）否则 `beginTextEditingAt`（`qke` 激活等价） |
| `gtc` 命中非文本成员 → `ttc` → `qke` 非文本 no-op（消费） | 纯组选区（选中实体=组叶子集）命中非文本成员 → 消费不拖拽 |
| `gtc` 文本成员/非成员、`ftc` 任意 → `wtc` | 其余 → 既有整体拖拽 |

## 6. 有界偏差

- `itc` 文本块 `ttc` 命中时原版还会同时跑链接探测与激活；Harmony
  先探测链接（命中出菜单不进入编辑），未命中才 `beginTextEditingAt`
  ——激活延迟到非链接点按，语义近似。
- `gtc` 非文本成员 `ttc` 下游即 no-op（`qke` 只对文本块生效），
  Harmony 直接消费手势不拖拽，行为等价。
- `ufb.I`（"是否已在编辑"门控）/`z2` 标志在 Harmony 无对应层，
  以"链接命中优先、否则激活"近似。
