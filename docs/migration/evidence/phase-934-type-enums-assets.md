# Phase 934 证据 — 类型枚举三件套 + dp5/akb 资产表

## 目的

rl2/dm2 剩余字段类型枚举 + 两个资产包装表实名。

## 枚举（实证）

- `t16` = **`StrokeStyle{VARIABLE_WIDTH=0,
  FIXED_WIDTH=1, DASH=2, DOTS=3}`** ——
  dm2/wd8 `style` 字段。
- `ty0` = **`CornerStyle{SQUARE=0, ROUND=1}`** ——
  rl2/td8 `corner` 字段。
- `cz0` = **`BlockType{TEXT=0, IMAGE=1, MATH=2}`** ——
  rl2/td8 `type` 字段。

## `dp5` = `ImageAsset`（实证）

```
j() → c(4): metadata:wa0 必需（"required field metadata"）
k() → c(6): size:qed 必需（"required field size"）
toString: "ImageAsset(metadata=, size=)"
```

rl2 `image` 字段的目标表。

## `akb` = `RecordingAsset`（实证）

```
j() → c(4): metadata:wa0 必需
toString: "RecordingAsset(metadata=)"
```

yn2 `recording` 字段的目标表——录音资产仅包装
AssetMetadata（时长等其余在 op 字段）。

## 结论

类型枚举三件套 + 两资产表实名：
ImageAsset={metadata,size} 双必需；
RecordingAsset={metadata} 单必需。
