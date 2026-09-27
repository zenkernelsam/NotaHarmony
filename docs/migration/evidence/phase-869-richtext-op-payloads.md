# Phase 869 证据 — 富文本 op payload 模式登记（类型 7–14）

## 目的

登记 `haa` 类型 7–14 的八个文本相关 payload 表的字段模式
（zq9 映射 + 逐表字段），核对 Harmony 文本 op 编码器。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### zq9 表→类型映射

```
e46 -> INSERT_CHAR(7)        pub -> REMOVE_CHAR(9)
f46 -> INSERT_STRING(8)      qub -> REMOVE_CHARS(10)
f2c -> REVIVE_CHARS(11)      me8 -> MODIFY_STYLE(12)
he8 -> MODIFY_PARAGRAPH_STYLE(13)   io1 -> CLEAR_STYLE(14)
```

### 逐表字段（vtable 偏移→字段号）

| 表 | f0 (c(4)) | f1 (c(6)) | f2 (c(8)) | f3 (c(10)) |
|----|-----------|-----------|-----------|-----------|
| e46 | cxc 位置 | int 字符 | qo5 目标 | — |
| f46 | cxc 位置 | String 文本 | qo5 目标 | — |
| pub | cxc 位置 | qo5 目标 | — | — |
| qub | **cxc 向量**（`l(i,cxc)` 步长 12 + `j()` 长度） | qo5 目标 | — | — |
| f2c | **cxc 向量**（同 qub） | qo5 目标 | — | — |
| io1 | v01 范围 l() | v01 范围 j() | boolean | qo5 目标 |
| me8/he8 | 样式/段落样式表（857 已登记 ka4 校验） | | | |

要点：

- 单字符 op（e46/f46/pub）携带**单个** cxc 位置；批量删除/
  复活（qub/f2c）携带 **cxc 向量**（12B 步长逐个取）——
  与原版的「一次命中一个位置」vs「一次命中位置集合」区分。
- 全部文本 op 以 `qo5` op-id 指明目标块；`v01` 为样式/范围
  结构（io1 两个 v01 = 起止区间）。
- `qub.l(i,cxc)` 越界走 `h34.l(fa2.i(...))` 断言而非返回 null ——
  生成的向量访问器 fail-fast 模式。

## Harmony 侧

- `OriginalInsertTextPayloadEncoder`：INSERT_CHAR/STRING +
  REMOVE_CHAR(S)/REVIVE_CHARS 判定（visible → REVIVE else
  REMOVE_CHARS），向量式写出。
- `OriginalRichTextStyleOperation`：类型 12/13/14 全覆盖，
  payload-type 分派。
- `OpTypes`：类型 7–14 常量齐备。

## 结论

文本 op 八表的字段模式与位置语义（单位置 vs cxc 向量、
qo5 目标）登记完毕；Harmony 编码器与类型分派等价。
纯文档+fixture 阶段。
