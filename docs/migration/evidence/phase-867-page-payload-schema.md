# Phase 867 证据 — 页面 payload 模式登记（ln2/nz9/sw9 + 子结构）

## 目的

登记 CREATE_PAGE / MODIFY_PAGE 的 payload 模式：`ln2` 创建页
表、`nz9` 页面外观表、`sw9` PDF-in-asset 表、内联结构
`vy7`/`qed`/`mmf` 与背景子表 `k3a`。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `ln2` — CreatePage payload（vtable 偏移→字段号 (n-4)/2）

| vtable | 字段 | 读法 | 含义 |
|--------|------|------|------|
| c(4) | f0 | `l()` → cxc | 位置（`nti.g(opId, pageInPayload)` 亦可派生） |
| c(6) | f1 | `j()` → nz9 | 页面外观/背景表 |
| c(8) | f2 | `m()` int **默认 1** | pageInAsset 起始页号 |
| c(10) | f3 | `k()` byte→oz9 | bookmark（默认 UNBOOKMARKED=0） |

### `nz9` — 页面外观表

| vtable | 字段 | 读法 |
|--------|------|------|
| c(4) | f0 | `k()` → k3a 背景子表 |
| c(6) | f1 | `l()` → sw9 PDF-in-asset |
| c(8) | f2 | `m()` float 默认 0.0 |
| c(10) | f3 | `n()` → qed 2-float 结构（尺寸） |
| c(12) | f4 | `j()` → vy7 4-float 结构（颜色/矩形） |

### `sw9` — PDF-in-asset 表

| vtable | 字段 | 读法 |
|--------|------|------|
| c(4) | f0 | `m()` → wa0（PDF 资产引用） |
| c(6) | f1 | `l()` → xw9（页范围/信息） |
| c(14) | f6 | `j(int,qed)`/`k()` —— 页尺寸向量 + 计数 |
| — | — | `n()` int —— PDF 总页数（`wz9.m` 用它减出页内偏移） |

### 子结构 / 值类

- `vy7`（xwd struct）：c/d/e/f 四 float（16B）—— 颜色或矩形。
- `qed`（xwd struct）：c/d 两 float（8B）—— 点/尺寸。
- `mmf`：Kotlin inline value class 包 int `I`，Comparable ——
  pageInAsset 序数包装（`wz9.m` 从寄存器赢家取 `mmf.I`）。
- `k3a`（cee 表）：`j()`→hu1、`k()`→n3a、`l()/m()`→Boolean×2。
- `ln2.k()` 的 byte→oz9 读取：差分索引 `b - oz9[0].I` 越界则回
  默认值——生成的枚举安全解码模式。

## Harmony 侧

`OriginalCreatePagePayloadEncoder.ets` 已逐字段写出 ln2：

- vtable `[cxc位置, nz9背景, pageInAsset, bookmark]` 四项 +
  `writeSequence` 精确写 cxc 12B 结构（siteId@0/ts@4/index@8）。
- 注释已标注 ln2 字段语义与 `wz9.u`/`haj.a` 的 bookmark 回写
  （duplicate 流通过 oz9 寄存器透传）。
- `OriginalDefaultTemplate`/`PageBackgroundModel` 承载 nz9 外观
  等价模型（纸张/pdf/尺寸）。

## 结论

页面 payload 模式与原版权属一致登记；Harmony 的 ln2 写手与
cxc 结构布局逐项等价。nz9/sw9 深层子字段（vy7/qed/k3a/hu1/
n3a/wa0/xw9）留档备后续逐字段审计。纯文档+fixture 阶段。
