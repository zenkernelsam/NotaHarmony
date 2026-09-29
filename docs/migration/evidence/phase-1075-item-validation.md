# Phase 1075 证据 — ddg.e 变换项校验 + 包装类型 + fsi.P

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ddg.e(ie8)` = 三段短路校验

```java
String e(ie8 it) {
    String s = o(it.k(), it.j());           // ① page+origin
    if (s == null) {
        k2d rot = it.l();
        s = (rot==null||rot.j()==null) ? null
            : l("Rotation", rot.j());        // ② rotation
        if (s == null) {
            y2d sc = it.m();
            if (sc==null || sc.j()==null) return null;
            return j(sc.j());                // ③ scale
        }
    }
    return s;
}
```

- 顺序：① page/origin `o()` → ② rotation `l("Rotation",f)` →
  ③ scale `j(qed)`；null 字段跳过。
- 修正 1074：l()=k2d→**rotation(Float)**，m()=y2d→**scale(qed)**。

## `k2d`/`y2d` = 可选值包装（SetXxx 单字段）

`k2d.j()→Float`（rotation）、`y2d.j()→qed`（scale）——
可为 null 表示不修改。

## `fsi.P(uq9)` = positionLocked 判定（1072 引用）

`fsi.K(uq9)`/`fsi.P(uq9)` 供 MODIFY_POSITIONS 分支。

## Harmony 决策

- 校验短路序保留；包装 null=不改。

## 产出

- fixture `d02-item-validation.mjs`（10 断言）。
- ADR-1019；中文报告。
