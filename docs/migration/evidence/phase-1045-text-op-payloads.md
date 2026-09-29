# Phase 1045 证据 — 文本 CRDT 操作载荷族

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 字段布局（vtable 槽位 / required 标记）

| 载荷 | haa | 字段（toString 实名） |
|---|---|---|
| `e46` InsertChar | 7 | `location:cxc`, `unicodeScalar:int`, `textField:qo5` |
| `f46` InsertString | 8 | `location:cxc@4`, `string:String@6 **required**`, `textField:qo5@8` |
| `pub` RemoveChar | 9 | `location:cxc **required**`, `textField:qo5` |
| `qub` RemoveChars | 10 | `locations:cxc[]`（`lv2.N` 向量化）, `textField:qo5` |
| `f2c` ReviveChars | 11 | `locations:cxc[]`（`lv2.O`）, `textField:qo5` |

- `qo5 textField` = 所属文本块锚点 opId；`cxc location` =
  页内字符位置。
- required 字段缺失 → `o14.i("No value for (required)
  field X")`（fail-loud 日志）。

## `ka4.a()` 校验（实测）

- `e46`：`Character.isValidCodePoint(l())` 否则
  `"Cannot create character from unicodeScalar: "+mmf.a(l())`。
- `f46`：`k().length()==0` → `"Cannot insert empty string"`。
- `pub`：恒 null（无校验）。
- `qub`/`f2c`：`j()<=0` → `"Must specify more than 0 locations"`
  （j()=locations 向量长度）。

## 辅助

- `mmf.a(int)` = unicode 标量格式化器。
- `lv2.N(qub)`/`lv2.O(f2c)` = locations 向量→List 访问器。
- equals/hashCode：`ba6.o` 等值 + `ldj.z2(cxc)` 哈希。

## HarmonyOS 决策

- 5 个文本操作字段布局与 required 语义逐一对齐；
  校验文案原样保留。
- unicodeScalar 用 `Character.isValidCodePoint` 等价判定。

## 产出

- fixture `d02-text-op-payloads.mjs`（12 断言）。
- ADR-0989；中文报告。
