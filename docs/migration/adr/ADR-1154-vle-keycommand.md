# ADR-1154：vle 键命令层（xl6 48 命令）

## 状态

已接受（Phase 1210）。

## 决策

`xl6` 48 命令枚举 + `pm6` 平台键映射 + `ysc` 执行
上下文 → ArkTS 键命令枚举 + ctrl/shift 键查表 +
编辑器执行器；`I` 需编辑门 → 命令前置校验。

## 理由

`xl6` = Compose `KeyCommand` 式硬件键盘编辑表
（导航 17/剪贴板 3/删除 6/选择 18/插入 2/历史 2/
CHARACTER_PALETTE），`pm6.a.k` 查表、`ysc` 上下文
求值、`ek8`/`qv2`/`jl4` 辅助。

## 后果

Harmony 编辑器硬件键盘 = 48 命令全集 + 编辑门 —
快捷键行为保真。
