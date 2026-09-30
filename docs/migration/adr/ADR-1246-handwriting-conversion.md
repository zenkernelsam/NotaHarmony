# ADR-1246：手写转文本/数学

## 状态

已接受（Phase 1302）。

## 决策

MyScript iink 不可用 → fail-closed（ADR-1168）；转换
UI/选区校验/几何分析 → 可移植保留；识别引擎 → 需
替代或 fail-closed。

## 理由

`dhb` = 手写→数学/文本转换（选区"spans pages"校验+
失败提示+笔画几何分析+结果应用回调）—— MyScript
iink 集成 UI，引擎不可移植但选区/校验/失败 UI 可移植。

## 后果

Harmony 手写转换 = 选区/校验/失败 UI 保留 + 识别引擎
fail-closed —— 转换 UI 语义保真+引擎降级。
