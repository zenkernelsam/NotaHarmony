# 原版证据：区域选区剔除 positionLocked 元素（fu1.b → jrh.a）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 608 依据。

## 1. 锁过滤（fu1.java:35-48 `b`）

```java
public static Set b(x09 x09Var, Set set) {
    if (!lc4.a(ac4.Q)) return set;                 // POSITION_LOCKED 关 → 全保留
    for (vnd : set) {
        be5 be5VarI = tl7.I(x09, id, 6);
        if (be5VarI == null || !jrh.a(be5VarI)) {  // 解析失败/未锁 → 保留
            linkedHashSet.add(obj);
        }
    }
}
```

`ac4.Q` = POSITION_LOCKED，`zb4.L` = PRODUCTION 档——`lc4.a` 默认
返回 true（远程开关可覆盖），即**锁过滤默认开启**。

## 2. 锁判定（jrh.java:13-22 `a` + cih.java:18-21）

- `oy0` 块（文本/图片/数学）：`t()` —— positionLocked。
- `m4d`/`n5d` 形状：`cih.a(m4d) && n5d.t()` ——`cih.a` = `!n5d.y`
  （可锁形状门控，`ao2.v()` 定义属性）且 positionLocked。
- `s06` 笔迹等其余类型：`false` ——永不剔除。

## 3. 调用次序（uw2.java:62-75 / vo2.java:171）

```java
Set setB = fu1.b(x09, X1(fu1.f(uh5, k11, v09.J, x09, null)));
mqc = lc4.a(ac4.V) ? fu1.c(x09, setB) : new mqc(setB, ...);
```

矩形（uw2 case1）与套索（vo2）选区完成同一路径：
**f 区域命中 → b 锁剔除 → c 组扩展**。锁定元素先被剔除，随后
组扩展仅就可能命中的未锁成员展开（被组扩展拉入的锁定成员
不再二次过滤——fu1.c 无锁检查）。

## 4. 点按路径无过滤

`xtc.a`/`xtc.c`（xtc.java:28,77）直用 `fu1.e` 点探，不经过 `b`——
**点按可选中锁定元素**（UNLOCK/删除等操作仍可达）；`xtc.b`
tape 栈选（`fu1.f` 精确收集）亦无锁过滤（tape 不可锁）。

## 5. Harmony 缺口与修复

- 旧实现 `finalizeSelection` 对锁元素照常收集（区域选区可圈进
  锁定元素并拖动/删除——原版套索扫过锁元素时它们被钉住不动）。
- 修复：四类命中循环前置 `positionLocked === true → continue`
  （笔迹循环不剔——jrh.a(s06)=false）；剔除位于
  `resolveOriginalGroupSelection` 之前，与 f→b→c 次序一致。
- 点按路径（`applyTapSelect`/`topmostPageElementIdAt`）不过滤——
  点选锁定元素仍可解锁。
- 单元测试 `SelectionTool.test.ets` 同步修正语义（locked 块/形状/
  图片/数学从区域选区剔除）。

## 6. 偏差

- `cih.a`（`!n5d.y` 可锁形状门控）在 Harmony 简化为
  `positionLocked === true`：不可锁形状 `y=true` 时 `t()` 本就
  为假，剔除结果一致；仅当非可锁形状被异常置锁时行为有差
  （Harmony 会剔，原版不剔）——视为 fail-safe。
- `lc4.a(ac4.Q)` 远程开关可关闭过滤；Harmony 按默认开实现。
