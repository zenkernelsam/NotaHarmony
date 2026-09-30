# ADR-1077：样式文本段（双锚 span）

## 状态

已接受（Phase 1133）。

## 决策

- `s3c` = 文本段 `{attrs×2, CharSequence, spacing, offset,
  exc f..g, fontSize, cpLen}` —— 双锚区间 span。
- `s3c.a` = copy-with 掩码派生；码点长度非 UTF-16。

## 依据

ctor 算 codePointCount + 双 exc 锚 + copy 工厂。

## 后果

Harmony 段 = `{attrs, text, offset, 锚区间, cpLen}`；
Record partial-copy 复刻。
