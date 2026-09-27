# Phase 868 证据 — 纸张/PDF 子模式登记（k3a/n3a/hu1/wa0/xw9/ge8）

## 目的

补齐 Phase 867 留档的深层字段：`k3a` 纸张背景表、`n3a` 纸纹
枚举、`hu1` RGBA 结构、`wa0` PDF 资产表、`xw9` PDF 适配枚举，
以及 `ge8` MODIFY_PAGE payload 字段图。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `ge8` — MODIFY_PAGE payload（zq9 登记 type 4）

| vtable | 字段 | 读法 | 含义 |
|--------|------|------|------|
| c(4) | f0 | `m()` | pages：SeqId 向量（目标页位置集） |
| c(6) | f1 | `l()` → lxc | moveTo：页移动指令 |
| c(8) | f2 | `j()` → m2d | background 更新（f0 嵌套新 nz9） |
| c(10) | f3 | `k()` → oz9 | bookmark 更新 |

（与 857 登记的 `ge8 implements ka4` 校验契约同一表。）

### `k3a` — 纸张/背景子表（nz9.f0）

| vtable | 字段 | 读法 |
|--------|------|------|
| c(4) | f0 | `k()` → n3a 纸纹枚举 |
| c(6) | f1 | `n()` Float —— 间距 |
| c(8) | f2 | `l()` Boolean |
| c(10) | f3 | `m()` Boolean |
| c(12) | f4 | `j()` → hu1 RGBA 结构 |
| c(14) | f5 | `o()` → cmf |

### `n3a` — 纸纹枚举

```java
LINES(0), DOTS(1), GRID(2)
```

### `hu1` — 4 字节内联结构

xwd struct：`c/d/e/f` 四个 byte —— RGBA 颜色（4B）。

### `xw9` — PDF 适配枚举

```java
DOWNSCALING_AND_MAX_BOX(0),
DOWNSCALING_AND_CROP_BOX(1),
FIT_AND_CROP_BOX(2)
```

### `wa0` — PDF 资产引用表（sw9.f0）

| vtable | 字段 | 读法 |
|--------|------|------|
| c(4) | f0 | `j()` → ua0 子表 |
| c(6) | f1 | `k()` String |
| c(8) | f2 | `m()` String |
| c(10) | f3 | `l()` int 默认 0 |

## Harmony 侧

- `OriginalPaperFlair`/`PaperTemplate` {LINES, DOTS, GRID}：
  n3a 枚举已移植；`flairBleeds: template !== LINES` 保留
  线纸不溢出、点/格纸出血的原版语义。
- `OriginalModifyPagePayloadEncoder`：注释逐字段对应
  ge8 `pages(vector<SeqId>)/moveTo(lxc)/background(m2d)/
  bookmark(oz9)`；空背景保留 m2d 字段同时省略 lxc f0，
  匹配 `egh.a(null)` 原版写法。
- `u5j.s(x09,[page],null,m2d,null,10)` 调用点语义已登记。

## 结论

纸张（n3a/k3a/hu1）、PDF（wa0/xw9/ua0）、MODIFY_PAGE（ge8/
lxc/m2d）模式全部登记；Harmony 枚举与字段语义一致。
纯文档+fixture 阶段。
