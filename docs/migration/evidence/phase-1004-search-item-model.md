# Phase 1004 证据 — SearchItem 模型 + 折叠算法 + 类型枚举

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `wkc` = 索引器侧 SearchItem 模型

```java
final class wkc {
    ttf a;      // noteId
    me2 b;      // type（枚举，下述）
    String c;   // subId（实体键）
    String d;   // rawText（待折叠原文）
    String e;   // pageId（可空，ctor 默认 null）
    String f;   // = ba6.s(a,b,c) 组合键
}
```

- `glc` 行构造（d6c:39）：
  `glc(type=b.ordinal(), noteId=a.toString(), subId=c,
  pageId=e, foldedText=nnc.a(d))` —— **写入侧折叠**。

## `me2` = SearchItemType（7 值）

```
TITLE(0) MAIN_BODY_TEXT(1) TEXT_BLOCK(2) INK(3)
RECORDING_TRANSCRIPT(4) IMAGE(5) PDF(6)
```

- 覆盖：标题/正文/文本块/手写(识别文本)/录音转写/
  图片/PDF 文本 —— 全内容类型可检索。
- `search_item.type` 列存 `ordinal()`。

## `ba6.s(ttf,me2,subId)` = 组合键

```java
subId.isEmpty() → "{noteId} {typeOrdinal}"
否则          → "{noteId} {typeOrdinal} {subId}"
```

（`wkc.f`；对应 UNIQUE(noteId,type,subId) 索引。）

## `nnc.a(String)` = foldedText 折叠算法 ★核心

```java
static final dqb a = new dqb("\\p{Mn}+");   // 组合记号
static final dqb c = new dqb("\\s+");       // 空白折叠
static final Map b = {                      // 16 项定制折叠表
  ß→ss  æ→ae  œ→oe  ø→o  ł→l  đ→d  ð→d  þ→th
  ħ→h  ŧ→t  ı→i(dotless)  ﬀ→ff  ﬁ→fi  ﬂ→fl
  ﬃ→ffi  ﬄ→ffl
};
String a(str):
  Normalizer.normalize(str, NFD)     // 1 拆变音符
  a.f(norm, "")                      // 2 去 \p{Mn}+ 记号
  .toLowerCase(Locale.ROOT)          // 3 小写
  // 4 逐字符查表 b 替换（NFD 无法处理的连字/特殊字母）
```

- 与 FTS `unicode61 remove_diacritics 2` 互补：
  写入侧先把 ligature/special-letter 折掉，FTS 再折
  变音符 —— 双保险。
- `nnc` 另有 `a`（rects 序列化变体待确认）；`sq1`
  UPSERT 的 rects BLOB 由调用方序列化。

## 实体 `glc` = search_item 行

`{a=noteId, b=type:int, c=subId, d=pageId?,
e=foldedText, rects:byte[]}` —— `toString` 证字段名
`SearchItem(id=0,noteId=,type=,subId=,pageId=,
foldedText=,rects=)`。

## HarmonyOS 决策

- **折叠算法必须逐字复刻**：NFD + `\p{Mn}+` 移除 +
  ROOT 小写 + 16 项表（ß/æ/œ/ø/ł/đ/ð/þ/ħ/ŧ/ı/ﬀﬁﬂﬃﬄ）。
- `me2` 7 类序数、`ba6.s` 键格式、rects BLOB
  语义保留。

## 产出

- fixture `d02-search-item-model.mjs`（15 断言）。
- ADR-0948；中文报告。
