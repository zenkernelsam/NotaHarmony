# Phase 1048 证据 — 形状/组操作载荷

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ao2` CreateShape（17 字段，toString 实名）

`{page:cxc, origin:fqa, rotation:Float, scale:qed,
definition:cee 子表, tool:u16, style:t16, tapePattern:ife,
color:hu1, borderWidth:Float, fillColor:hu1, zIndex:tmf,
smartHighlight:bool, force:Float, positionLocked:bool,
inkEffects, inkEffectsTinted}`

校验：
- `style==t16.VARIABLE_WIDTH` → "Cannot create shapes with
  variable width ink"。
- `fillColor` 禁零 alpha：用 nil 表示未填充（cmf.I==0 拒绝）。
- inkEffects 仅 PEN/HIGHLIGHTER（"ink_effects require a Pen
  or Highlighter tool"）。

## `le8` ModifyShape（17 字段）

`{shapes:list(lv2.e0), page, origin, rotation, scale,
definition(z5c.w), tool, style, tapePattern, color,
borderWidth, fillColor, zIndex, positionLocked, inkEffects,
inkEffectsTinted}`——shapes>0 + 同款禁变宽校验
（"Shapes cannot use variable width ink"）。

## `cm2`/`vd8` 组操作

- `cm2` CreateGroup `{members:list(lv2.P)}`：members>0
  （"Cannot create a group with 0 members"）。
- `vd8` ModifyGroup `{group, members(lv2.Q)}`：members>0。

## 新类型

| 类 | 语义 |
|---|---|
| `t16` | 墨迹样式枚举：VARIABLE_WIDTH=0 FIXED_WIDTH=1 DASH=2 DOTS=3 |
| `cmf` | 颜色值类 `{byte I}`（I==0=透明禁用） |
| `fqa` | 原点坐标结构 |
| `ife` | tapePattern 类型 |
| `hu1` | 颜色类型 |
| `tmf` | zIndex 类型 |

## HarmonyOS 决策

- 形状 17 字段语义保留；VARIABLE_WIDTH/零 alpha/工具限制
  校验逐条保留；t16 4 值 wire 对齐。

## 产出

- fixture `d02-shape-group-ops.mjs`（12 断言）。
- ADR-0992；中文报告。
