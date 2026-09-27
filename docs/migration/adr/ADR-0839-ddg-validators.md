# ADR-0839 — `ddg` 校验助手全集 + ka4 实现面扩展

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ddg` 助手集：`a`=ε 比较（1e-4）、`d`=float 有限性、
  `l`=标签前缀包装、`i`=尺寸≥0、`j`=缩放校验、
  `k`=ka4 标签委托、`h`=点 x/y、`e`=文本修改
  （位置+旋转+缩放）、`m`=centerPath/styleMap 规则、
  `b/c/n/o`=路径·长整·迭代·点对校验。
- ka4 实现面扩展实证：qed、vy7、fqa（k()/a() 直调）。
- 统一语义：ε=1e-4、`"label: leaf-err"` 层级消息。

## Harmony 决策

编码侧 throw 门 + 数值守卫对齐 ε/有限性/层级格式；
centerPath-styleMap 一致性对齐墨迹路径编码门。

## Parity 状态

等价（校验助手全集实名，ka4 面扩展实证）。

## 验证

- `d02-ddg-validators.mjs`：15/15 通过。
- 全量 Replay 768 文件绿，见 Phase 895 提交。
