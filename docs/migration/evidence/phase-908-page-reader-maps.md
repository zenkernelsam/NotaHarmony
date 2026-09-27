# Phase 908 证据 — `ln2`/`nz9`/`k3a` reader accessor 图 + 读写对称闭合

## 目的

钉死页面/背景/纸面三表的读侧槽位，实证与写侧
（haj.a/vv7.L/fag.o0）逐字段对称。`decompiled_1.0.3`。

## `ln2` = CreatePage 读图（haj.a 对称）

| 访问器 | `c(N)` | 字段 | 写侧对应（877） |
|--------|--------|------|----------------|
| `l()` | c(4) | f0 `cxc` 内联 | `haj.a` arg0 |
| `j()` | c(6) | f1 `nz9` 间接 | arg1 可选背景 |
| `m()` | c(8) | f2 `int` | arg2 pageCount |
| `k()` | c(10) | f3 `oz9` | arg3 书签 |

## `nz9` = PageBackground 读图（vv7.L 对称）

| 访问器 | `c(N)` | 字段 | 写侧对应（886） |
|--------|--------|------|----------------|
| `k()` | c(4) | f0 `k3a` 间接 | field0 纸面 |
| `l()` | c(6) | f1 `sw9` 间接 | field1 PDF 布局 |
| `m()` | c(8) | f2 `float` | field2 旋转 |
| `n()` | c(10) | f3 `qed` 内联 | field3 尺寸 |
| `j()` | c(12) | f4 `vy7` 内联 | field4 边距 |

## `k3a` = PaperConfig 读图（fag.o0 对称）

| 访问器 | `c(N)` | 字段 | 写侧对应（888） |
|--------|--------|------|----------------|
| `k()` | c(4) | f0 `n3a` 枚举 | field0 模板 |
| `n()` | c(6) | f1 `Float` | field1 |
| `l()` | c(8) | f2 `Boolean` | field2 |
| `m()` | c(10) | f3 `Boolean` | field3 |
| `j()` | c(12) | f4 `hu1` 内联 | field4 颜色 |
| `o()` | c(14) | f5 `cmf` | field5 |

## 读写对称闭合

三张表的 `c(4+2·字段号)` 读槽 = 写侧 `C(N)` 内
`h/e/c/j/f` 写槽**逐一对应**——页面-背景-纸面子树的
读写公式完全互证（892/893 公式的实例化证据）。

## Harmony 侧

CreatePage/PageBackground/PaperConfig 解码 ↔ 槽位逐对；
getter 名-字段名映射表建立（l=location, j=background,
m=pageCount, k=bookmark…）。

## 结论

页面子树读写对称闭合；accessor→字段→偏移三层实名。
纯文档+fixture 阶段。
