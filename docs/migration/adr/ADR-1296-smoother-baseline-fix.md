# ADR-1296：ForceSmoother 基线归属更正

## 状态

已接受（Phase 1355，更正 Phase 1325）。

## 决策

ForceSmoother 基线更正：`hr4`/`dr4` 实为文本标题样式
枚举（非平滑器）；Harmony 实现保留为文档化近似。

## 理由

实读：`hr4`=enum-like（`Enum.valueOf`+`fr4("Heading3",
3,true,18.0f)` —— Heading 样式枚举+字号），`dr4` 为
枚举项，`jr4` 接口 —— 非笔画平滑器。原版真实平滑器
未在混淆名中定位。Harmony `ForceSmoother`（8ms EMA+
0.15 maxChange 钳制）实现正确、基线引用更正。

## 后果

三大算法基线引用（1325 平滑/1326 拟合/1327 检测）
均完成误标更正 —— 审计诚实性修复。
