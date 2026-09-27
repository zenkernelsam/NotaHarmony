# Phase 886 证据 — `vv7`/`nz9` 页背景构造与序列化

## 目的

登记 `nz9` 页背景的完整字段线格式与 `vv7` 工厂/序列化器
（`decompiled_1.0.3`；867 已登记字段层，本阶段补构造面）。

## `nz9` 字段（`vv7.M` 写侧实证）

`M(a, k3a, sw9, Float, qed, vy7)` → `C(5)` 五字段表：

| 字段 | 类型 | 访问器 | 序列化器 | 语义 |
|------|------|--------|----------|------|
| 0 | `k3a` | `k()` | `fag.n0` | 纸面/背景配置（867：模板+颜色） |
| 1 | `sw9` | `l()` | `j7j.c` | PDF-in-asset 布局 |
| 2 | `Float` | `m()` | `d(2,f,0.0)` | 旋转角（FB 默认 0.0） |
| 3 | `qed` | `n()` | `apb.Z` | 页面尺寸（2f 宽高） |
| 4 | `vy7` | `j()` | `fsi.b0` | 四元 quad（4f 裁切/内距?） |

`vv7.L(nz9, a)` = 再序列化器：逐项调用 `M`（haj.a/c 嵌入用）。

## `vv7.f` = `nz9` 工厂（Kotlin 存根）

`f(k3a?, sw9?, Float?, qed?, vy7?, int mask)`：`&1`→paper、
`&2`→pdf、`&4`→rot、`&8`→size、`&16`→vy7 各自默认 null；
建表→`ybg.c` 校验→返回。

- **掩码 54 = bit1+2+4+5**（a79.Q 实传）：sw9/rot/vy7 默认 +
  **参数序号 5 再一省略参数**（同 haj.a/wq9 模式——JADX
  类型推断失败致参数+分支省略，线格式无第 6 字段）。
- a79.Q = `vv7.f(fag.k(tu1 色纸,…), null, null, N=Letter,
  null, 54)` = 默认纸背景：有色纸 + Letter 尺寸。

## `vv7.N(x09)` = 全文档背景收集器

遍历 `a79Var.J`（bja）+ `a79Var.D`（cl2）——收集文档中全部
nz9 背景（缩略图/导出面用）。

## `vv7` 混合静态属性

Compose/杂项静态合流（a..K 无关方法）——与 *0j 同型混淆。

## Harmony 侧

- `encodeOriginalPageBackgroundTableBlob`：五字段 nz9 表与
  `vv7.M` 字段序一致（867 已对齐 paper/size/PDF 槽）。
- a79.Q 默认纸 ↔ Harmony `PageBackgroundModel` 默认；
  `vv7.f` 全可空形态 ↔ Harmony 背景编码可空入参。

## 结论

nz9 五字段线格式 + vv7.f/L/M/N 构造序列化收集全实名；
默认纸 = 色纸+Letter。又一例「掩码高位 = 省略参数序号」
佐证（54 含 bit5）。纯文档+fixture 阶段。
