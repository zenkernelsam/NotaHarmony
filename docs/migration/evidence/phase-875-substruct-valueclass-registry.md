# Phase 875 证据 — 子结构/值类/余枚举登记

## 目的

登记 op payload 图中的全部内联结构、Kotlin 值类与余下枚举，
完成实体-线层类型清单。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### 内联结构（xwd struct，按字节布局）

| 类 | 布局 | 语义 |
|----|------|------|
| **ua0** | **8×Long（64B）** | **SHA-512 资产内容哈希**（`assets/<sha512>` 键；NoteExporter 已引） |
| qo5 | Short@0+Int@4（8B） | op-id {site u16, ts u32} |
| cxc | Short@0+Int@4+Int@8（12B） | 位置 {site, ts, index} |
| utf | 2×Long（16B） | UUID（859 已登记） |
| hu1 | 4×Byte（4B） | RGBA 颜色 |
| qed | 2×Float（8B） | 点/尺寸 |
| vy7 | 4×Float（16B） | 矩形/颜色 |
| fqa | 2×Float（8B） | 点/尺寸（另一形态） |
| v01 | byte@+12（13+B） | 样式/范围标记（含 cxc 前缀） |
| ukb | 2×Long（16B） | 录音段 {startMs, endMs} |
| bmb | 结构 | 块相关子结构 |
| hd1 | 结构 | 批注子结构 |

### Kotlin 值类（inline value class，`implements Comparable`）

| 类 | 载荷 | 语义 |
|----|------|------|
| tmf | long I | op/记录时间戳（u64） |
| xgb | long I | 寄存器挂钟（866 赢家单元辅助） |
| mmf | int I | pageInAsset 序数 |
| cmf | byte I | 字节包装 |
| ymf | （Comparable） | 路径元素类型包装 |
| imf | 普通类 | — |

### 余枚举

| 枚举 | 值 |
|------|-----|
| ww9 | STRING, BOOLEAN（PDF 字段值类型） |
| u76 | POINTER, PEN, HIGHLIGHTER, ERASER（对端指针类型） |
| 已知 | u16/t16/ife/z4d/ty0/ive/im/oz9/n3a/xw9（865/868/874） |

### 单字段/二字段小表

`z1d`/`lxc`/`m2d`/`akb` = 1 字段表；`dp5`/`qqe` = 2 字段表。

## Harmony 侧

- `NoteExporter` 注释已引 `ua0`（CREATE_RECORDING 资产哈希）——
  `assets/<sha512>` 键与 64B 结构对应。
- op-id/位置/UUID 等已由 OperationIdentity/cxc 层覆盖；
  值类语义由对应持久列承载。

## 结论

线层类型清单闭环：31 payload 表 + setter 包装 + 内联结构 +
值类 + 枚举全登记。纯文档+fixture 阶段。
