# Phase 980 — `ar6` SchemaVersion 枚举全史 + `rgc.a`=15

来源：`decompiled_1.0.3/sources/defpackage/{ar6,rgc}.java`

## 1. `ar6` = SchemaVersion 枚举（0–15 完整历史）

```java
PRE_SHIPPING(0)
ALPHA_1(1)
LAYOUT_MODE(2)
CHECKBOX_OP(3)
SHAPES_FORCE(4)
TEXTBOX_MARGINS_AND_RESIZING_TO_FIT_TEXT(5)
DECORATOR_STYLE(6)
BLOCKS_AND_SHAPES_POSITION_LOCK(7)
PEER_INTERACTION(8)
TAPE_PATTERN(9)
WRITING_DIRECTION(10)
CODE_AND_CALLIGRAPHY(11)
COMMENTS(12)
MODIFY_INK_TAPE_PATTERN(13)
BLOCK_WRAP_SUPPORT(14)
INK_EFFECT(15)          // ← K = new ar6(15) = 当前版本
```

`public final short I` = 序号载荷；`J` = zq6(0)
（EnumEntries 助手）；`K` = 当前版本单例 = **15**。

## 2. `rgc.a` = 当前 schemaVersion

```java
public static final short a;
static { a = ar6.K.I; }   // = 15
```

`q4j.c` 写 NoteBundle f7、`nce` 版本闸
`ba6.w(bundle&0xFFFF, rgc.a&0xFFFF)` 皆引此——
**读写共用同一常量源**。

## 3. 版本→特性映射的协议意义

每版本对应一线型特性闸门：v2 layoutMode、v3
checkbox op、v4 shapes force、v5 textbox margins/
resizeToFit、v6 decoratorStyle、v7 positionLock、
v8 peerInteraction、v9 tapePattern、v10
writingDirection、v11 code/calligraphy、v12 comments、
v13 modifyInk tapePattern、v14 blockWrapSupport、
v15 inkEffect。

**读侧版本闸语义**：文件 schemaVersion > 当前 =
更新版本写入 → Stale 处理（fail-closed，不静默丢字
段）。此即各 op 表"特性版本"门控的根。

## 4. Harmony 对齐

Harmony 写侧 schemaVersion 常量须 = **15**；
读侧 u16 比较已对齐（979）。

## 5. 验证

`d02-schema-version.mjs` 静态断言（16 枚举项+K=15
+rgc.a 委托）。
