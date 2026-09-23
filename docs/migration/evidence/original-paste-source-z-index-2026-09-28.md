# 证据：原版剪贴板粘贴的源 zIndex 保留（o8j / u6a / ge3 / ry0）

- 日期：2026-09-28；Phase 629
- 原版来源：`decompiled_1.0.3/sources/defpackage/o8j.java`、
  `u6a.java`、`ge3.java`、`a5g.java`、`ks.java`、`hp5.java`、
  `u08.java`、`cie.java`、`kp5.java`、`u5j.java`、`baj.java`
- Harmony 实现：`note/src/main/ets/data/StrokePersistence.ets`

## 原版语义

剪贴板序列化按元素种类分不对称携带 zIndex：

1. **Ink 记录 `u6a` 携带 `public final long j`（u6a.java:16）**
   —— 序列化的源 zIndex。粘贴生产者 `o8j.a`（o8j.java:297）以
   `new xgb(u6aVar2.j)` 原样回填 `u5j.g` 的第 16 参（xgb zIndex
   槽，u5j.java:557）。即：Ink 粘贴**逐字保留源 z** —— 包括
   999999 衬底带（复制衬底荧光笔再粘贴仍为衬底）与同 z 冲突
   （同页 copy+paste 与源同 z，序由副键打破）。
2. **Shape 记录 `ge3` 无 z 字段**（ge3.java:4-29：g5d/h8d/cxc/
   fqa×2/v4d/Float/u16/t16/hu1/float/Float，无 long/xgb 成员）。
   `u5j.j`（u5j.java:684）的 xgb 第 11 参在全部调用方均传
   `null`：`a5g.java:540`、`ks.java:157` → 解码端回退
   clientTime（顶层）。
3. **Block 生产者 `baj.a`（baj.java:13）第 10 参为 xgb**；
   `hp5.java:168`、`u08.java:149`、`cie.java:167`、
   `kp5.java:24`（IMAGE）全部传 `null` → clientTime。
4. Group create op 负载仅成员列表，z 落 op clientTime。

净效果：**原版只有 Ink 粘贴保留源 z**；Shape/Text/Image/Math/
Group 粘贴一律 clientTime 顶层序。

## Harmony 对齐点

`StrokePersistence.ets` `commitOriginalClipboardPaste`：

- 新增 `readOriginalClipboardSourceZIndex`（:5803）：按
  `ref.elementId`（源元素 op-id）解码 OperationIdentity，
  查 `original_element_z_index` 取 `z_index`。查询**不带**
  note/page/visible 约束 —— 元素 op-id 全局唯一，跨页/跨笔记
  粘贴与 cut 源（visible=0 行仍保留 z_index）均命中；无行或
  多行 → `undefined`（fail-closed 回退）。
- 循环内仅 `ref.kind === STROKE` 时求值并传入
  `encodeOriginalLocalCreateInk(page, stroke, sourceZIndex)`
  —— 与原版"仅 Ink 记录携带 z"的不对称性一致。
- Shape/Text/Image/Math 不传 z → 编码端缺省 → 解码端
  clientTime —— 与原版 `xgb=null` 路径同约。
- 既有 z-clock 护栏收窄为逐元素判定：仅当元素回退 clientTime
  （`sourceZIndex === undefined`）时才校验
  `clientTime > maximumZIndex`；显式源 z 元素按原版语义
  逐字插入，不受顶层序护栏约束。

## 编码器补全（格式完整性，非行为变更）

原版 CreateInk(field 14)/CreateShape(field 12)/CreateBlock
(field 9) 线格式均含 u64 zIndex 槽，解码端已读。本次把
`encodeOriginalLocalCreateShape`（offset 28-35 空洞）与三个
`encodeOriginalLocalCreate*Block`（objectSize 条件 +8）补齐
`zIndex?: string` 形参；当前仅 Ink 粘贴路径接线，其余形参
缺省 → 字节零变化。

## 有意不移植 / 边界

- 原版在**复制时**把源 z 固化进剪贴板记录；Harmony 在**粘贴
  应用时**读 `original_element_z_index` 当前行。若复制与粘贴
  之间源元素 z 被修改（如置顶后再粘贴），原版用复制时刻旧 z、
  Harmony 用当前 z —— 窄边界，方向仍 fail-closed（合法 z 值）。
- Group z 保留不在本期：原版 group create 负载无 z 槽，Harmony
  `encodeOriginalCreateGroup` 同为 members-only，z 落 clientTime
  —— 两端同约，无差异。
- 跨笔记粘贴：元素 op-id 全局唯一，行查询可命中源笔记的
  `original_element_z_index` 行 —— 行为与原版记录序列化一致
  （z 值作为标量跨笔记仍有效）。

## 验证

- `d04-original-paste-source-z-index.mjs`：38/38（原版结构断言
  + Harmony 挂接断言 + 源 z 解析仿真：cut 源/缺席/多行回退）。
