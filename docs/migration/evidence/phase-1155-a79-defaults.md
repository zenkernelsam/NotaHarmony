# Phase 1155 证据 — a79 静态默认 + 7 元数据属性

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `a79` 静态默认

```java
N = apb.h(612f, 792f)         // qed 页尺寸 = US Letter!
O = fsi.f(36,36,36,36)        // vy7 margins = 36pt = 0.5"
P = N.d()/8.5f ≈ 93.18        // pt/inch 密度
Q = vv7.f(fag.k(…tu1.a…,111), …, N, …,54)  // nz9 页背景默认
R = w69                                        // 另一默认
er6 L = new er6(3)                              // Companion
```

- `N` = **612×792 = 8.5"×11" US Letter @72dpi** —— 默认
  页尺寸。
- `O` = **36pt** 四边 margins = 0.5 英寸。
- `P` = `792/8.5 ≈ 93.18` pt/inch。
- `apb.h` = 尺寸工厂；`fsi.f` = margins 工厂。

## 7 元数据 `w1b` 属性（`fl6[] M`）

```java
title:String, defaultFontFamily:String,
defaultFontSize:Float, alignTextToLines:Boolean,
layoutMode:LayoutMode, blockWrapSupport:BlockWrapSupport,
handwritingLanguage:String
```

笔记元数据 = 7 个 LWW 委托属性（Phase 1121 名）。

## `a79.a(…27 args…, i2)` = copy-with mega

27 参 copy-with：kia/Set/f1a/Map/List/ue4/cl2/mja/hja/
qja/bja×4/uia/yc6×8/m4c/lja + `i2` 掩码 —— live note
全字段派生。

## 语义

note 默认 = US Letter 页 + 0.5" margins + 93.2dpi + 默认
背景 + 7 元数据 LWW；copy-with 27 参全派生。

## Harmony 决策

- 默认页 = 612×792 Letter；margins 36pt；dpi 792/8.5；
  元数据 = 7 LWW 属性。
- Harmony：默认常量 + copy-with 掩码派生。

## 产出

- fixture `d02-a79-defaults.mjs`（10 断言）。
- ADR-1099；中文报告。
