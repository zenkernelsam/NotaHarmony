# Phase 629 — 剪贴板粘贴源 zIndex 保留（o8j/u6a 对齐）

## 原版证据

- `u6a.java:16,23`：Ink 剪贴板记录携带 `public final long j` ——
  序列化的源 zIndex；
- `o8j.java:297`：粘贴 Ink 生产者调 `u5j.g(..., new
  xgb(u6aVar2.j), ...)` —— 第 16 参（xgb zIndex 槽）逐字回填
  源 z，含 999999 衬底带与同 z 冲突（副键打破）；
- `u5j.java:557`：`u5j.g` 签名第 16 参为 `xgb xgbVar`；
- `ge3.java:4-29`：Shape 记录无 long/xgb z 成员；
- `a5g.java:540`、`ks.java:157`：`u5j.j`（CreateShape 生产者，
  u5j.java:684 第 11 参 xgb）两个调用方均传 `null`；
- `baj.java:13`：`baj.a`（CreateBlock 生产者）第 10 参为
  `xgb`；`hp5.java:168`、`u08.java:149`、`cie.java:167`、
  `kp5.java:24`（IMAGE）全部传 `null`。

净效果：**原版仅 Ink 粘贴保留源 z**；其余种类粘贴落
clientTime 顶层序。

## Harmony 缺口

`commitOriginalClipboardPaste` 对所有种类省略 zIndex →
clientTime。Ink 分叉可观察：复制 999999 衬底荧光笔再粘贴
弹到顶层；原版保持衬底。

## 决策与实现

- `StrokePersistence.ets` 新增
  `readOriginalClipboardSourceZIndex`（:5803）：按源 elementId
  直查 `original_element_z_index`，无 note/page/visible 约束
  （op-id 全局唯一 → 跨页/跨笔记/cut 源均命中），无行/多行
  → `undefined` 回退；
- 粘贴循环仅 `STROKE` 求值并传入
  `encodeOriginalLocalCreateInk(page, stroke, sourceZIndex)`；
- Shape/Text/Image/Math 不传 z → clientTime（原版 null 同约）；
- z-clock 护栏收窄为逐元素判定：仅回退 clientTime 的元素
  校验 `clientTime > maximumZIndex`；
- 编码器补齐：`encodeOriginalLocalCreateShape` 增
  `zIndex?: string`（field 12 → offset 28 空洞）；
  `encodeOriginalLocalCreateTextBlock/ImageBlock/MathBlock`
  增 `zIndex?: string`（field 9 → objectSize 条件 +8，
  offset 72/80/64）+ `writeUint64Decimal` 助手。当前仅 Ink
  接线 —— 形参缺省字节零变化。

## 验证

- `d04-original-paste-source-z-index.mjs`：38/38（原版结构断言
  + Harmony 挂接断言 + 源 z 解析仿真：cut 源 visible=0 命中、
  缺席/多行回退、非 Stroke 不接线）；
- 全量 Desktop Replay、双 HAP clean 构建见收尾记录。

## 关联文档

- evidence：`original-paste-source-z-index-2026-09-28.md`
- ADR-0598
