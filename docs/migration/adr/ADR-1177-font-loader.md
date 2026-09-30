# ADR-1177：字体加载 + ReplacementSpan

## 状态

已接受（Phase 1233）。

## 决策

`lyb` ResourcesCompat+`ifj` 异步回调+`nlf` 内嵌 span
+`mac` Paint holder → Harmony `font` 框架 +
StyledString `CustomSpan`/`ImageSpan`。

## 理由

`lyb`=ThreadLocal+WeakHashMap 异步字体加载；
`ifj`=FontCallback；`nlf`=ReplacementSpan 读
CharacterStyle Typeface→独立 Paint 内嵌绘制；
`mac`=双 Paint —— 字体管线。

## 后果

Harmony 字体 = registerFont+FontDescriptor+StyledString
span —— 字体/内嵌语义保真。
