# Phase 920 证据 — setter 包装布局 + v01/tv6/dz0/y01

## 目的

setter 包装表内部布局 + 三个枚举值实名。

## setter 包装统一布局

| 类 | 名称 | 字段 | 载荷类型 |
|----|------|------|---------|
| `z1d` | `SetBool{value}` | c(4) | Boolean byte |
| `z2d` | `SetString{value}` | c(4) | String |
| `k2d` | `SetFloat{value}` | c(4) | Float |
| `y2d` | `SetSize{value}` | c(4) | `qed` |
| `g2d` | `SetColor{value}` | c(4) | `hu1` |
| `m2d` | `SetPageBackground{value}` | c(4) | `nz9` |

全部单字段 `{value@c(4)}`——setter 语义 = 值存在则改、
缺席则不动（三路态：null=不改 vs 有值=改为）。

## `v01` = `Boundary`（xwd 内联结构，非表）

`{location:cxc@0(12B), type:y01@12(byte)}` ——
**ModifyStyle start/end 的真实类型**：位置 ID +
边界方向枚举 = 文本范围的精确锚定。

## 枚举值实名

- `y01` = **BoundaryType**：`BEFORE=0, AFTER=1,
  START_OF_DOC=2, END_OF_DOC=3`。
- `tv6` = **LayoutMode**：`PAGED=0, PAGELESS=1`
  （ar6 LAYOUT_MODE=2 里程碑对应类型）。
- `dz0` = **BlockWrapSupport**：`WRAP_ENABLED=0,
  WRAP_DISABLED=1, LEGACY_WRAP_ENABLED=2`——三态含
  遗留迁移值（BLOCK_WRAP_SUPPORT=14 里程碑）。

## Harmony 核对

setter 单值槽对齐；Boundary 结构 = cxc+y01 12+1B；
LayoutMode/BlockWrapSupport 枚举值对齐（含
LEGACY_WRAP_ENABLED 迁移值）。

## 结论

setter 层完全闭合：统一 {value} 槽 + Boundary
复合锚点 + 枚举全集。
