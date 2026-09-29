# ADR-1065：活 note 聚合（x09/a79）

## 状态

已接受（Phase 1121）。

## 决策

- `a79` = 活 note：bundle 头 + **8 `yc6` 元数据 LWW 寄存器**
  （title/fontFamily/fontSize/alignText/layoutMode/blockWrap/
  handwriting）+ 7 `bja` + 2 `uia` 实体-map + spec/背景/默认。
- 元数据用寄存器（同实体属性），`w1b` 委托 + `LayoutMode`/
  `BlockWrapSupport` schema 枚举。

## 依据

w1b 属性描述泄漏实名 + 8×yc6 + bja/uia 集合。

## 后果

Harmony note 对象 = header + 8 元数据寄存器 + 实体-map 集合 +
spec/background；元数据走同一 LWW 应用管线。
