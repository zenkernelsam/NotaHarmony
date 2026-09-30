# Phase 1237 证据 — ls MotionEvent↔StrokeInput 对账 + link 粘贴

来源：`defpackage/{ls,ueg,lx5,jw5,hx5,o14,ix5}.java`。

## `ls implements ol4` = 多 emit 收集器

```java
case: ClipData.newPlainText("link", (String)obj);   // 剪贴板 link 粘贴
case: StrokeInput strokeInput = ueg.e;
    lx5.j.d.put(jw5, new hx5(matrix, ts, false, strokeInput.e));
case:
    o14.s("Stroke ID", jw5, "was started with a MotionEvent
        but finished with a StrokeInput");
```

## 语义

- `lx5.j.d` = `LinkedHashMap<jw5 strokeId, hx5>` —
  每笔状态 `{matrix, ts, MotionEvent?, StrokeInput}`；
- **MotionEvent↔StrokeInput 对账**：stroke 以 MotionEvent
  起始却以 StrokeInput 收尾（笔/手势工具中途切换）→
  `o14.s` 警告 —— 输入生命周期一致性校验；
- `ueg.e` = StrokeInput 单位/`null` 哨兵；
- ClipData "link" = 链接粘贴（剪切板→笔记超链接）；
- `ix5` = 另一笔状态类型（StrokeInput 分支）。

## Harmony 决策

AndroidX Ink StrokeInput → Harmony `onTouch` + 自研
stroke-input（或 fail-closed）；MotionEvent↔StrokeInput
一致性 → 输入生命周期日志；ClipData link →
`pasteboard` URI。

## 产出

- fixture `d02-ls-stroke-reconcile.mjs`（10 断言）。
- ADR-1181；中文报告。
