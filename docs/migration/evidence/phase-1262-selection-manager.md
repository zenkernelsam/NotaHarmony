# Phase 1262 证据 — joe/mse/r95/zne/tr1 选区管理器

来源：`defpackage/{joe,mse,r95,zne,tr1,wc5,zn9}.java`。

## `joe` = TextFieldSelectionManager

```java
joe { pdf a;              // 文本会话
      ype b;              // 布局几何
      r93 c;              // Density
      boolean d,i;
      k6f e;              // IME 会话
      hi2 f;              // 协程域
      yla g;              // TextClassifier（智能选择）
      tr1 h;              // HapticFeedback
      wc5 j;              // ClipboardManager
      Function0 l,m;      // 回调（selection-change）
}
```

## 枚举

- `mse` = **`HandleState`** `{None, Cursor, Selection}` —
  当前显示的句柄类型；
- `r95` = **`Handle`** `{Cursor, SelectionStart,
  SelectionEnd}` —— 拖拽的句柄；
- `zne` = **`TouchMode`** `{None, ...}` —— 交互模式；
- `zn9` = `Offset.Unspecified`（0x7FF8.. NaN-packed）。

## 语义

- `joe` = **TextFieldSelectionManager** —— 管理选区/
  光标句柄：focus/拖拽/长按→光标→选择 → `mse` 状态；
- `r95`/`mse`/`zne` = 句柄-类型 / 句柄-状态 / 触摸模式
  枚举 —— 光标 vs 选择 start/end 手柄；
- `tr1`/`wc5`/`yla` = 触觉/剪贴板/智能选择依赖；
- `zn9` = Offset.Unspecified 哨兵（句柄位置未设置）。

## Harmony 决策

TextFieldSelectionManager+句柄枚举 → Harmony
`TextInput`/`SelectController`+`CaretStyle` —— 选区
语义保真。

## 产出

- fixture `d02-selection-manager.mjs`（10 断言）。
- ADR-1206；中文报告。
