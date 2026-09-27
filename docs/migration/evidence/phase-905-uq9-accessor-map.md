# Phase 905 证据 — `uq9` Op 封套 accessor→vtable 偏移全图

## 目的

钉死 op 封套读侧契约（859 字段级注册的精确偏移）。
`decompiled_1.0.3`。

## `uq9` accessor 全图（c(4+2i) 槽位实证）

| 访问器 | `c(N)` | 字段 | 读法 | 语义 |
|--------|--------|------|------|------|
| `p(qo5)` | c(4) | **f0 id** | 内联结构 `qo5Var.b(i,bb)` | **必填**（缺→`o14.i` "No value for (required) field id"） |
| `k()` | c(6) | **f1** | `getLong` 默认 0L | clientTime |
| `n()` | c(8) | **f2** | `getLong`→`tmf` | serverTime |
| `j()` | c(10) | **f3** | `getLong`→`tmf` | audioTime |
| `m()` | c(12) | **f4** | `getByte`→haa 枚举 | payloadType |
| `q(cee)` | c(14) | **f5** | UOffsetT 间接 `d(getInt+i)` | payload（必填） |
| `r(sdf)` | c(16) | **f6** | UOffsetT 间接 `b()` | transientInteraction |

## `haa` 枚举读法（`m()` 实证）

```java
byte b = get(c(12)+I);
int i = (b & 255) - ((haa)nz3.get(0)).I & 255;
return (i<0 || i>=nz3.d()) ? nz3.get(0) : nz3.get(i);
```

- `nz3` = `haa.q0` EnumEntries（859）。
- **前向兼容**：越界/负值 → `get(0)` = NONE——未知
  payload 类型读为 NONE 不崩（Harmony 侧须同语义）。

## 读法三类模式

1. **内联结构**（qo5@f0）：`xwd.b(i,bb)` 绝对位直读。
2. **标量**（long/byte）：`get(c(N)+I)`，缺槽=0/默认。
3. **间接表**（cee/sdf）：`b(i+I)`=UOffsetT 随动→`d(abs,bb)`。

## Harmony 侧

`OriginalFlatBufferTableReader`/op 封套解析 ↔ 槽位偏移
4/6/8/10/12/14/16 一致；payloadType 未知值 → NONE
语义对齐；必填 id/payload 门对齐 z() required。

## 结论

uq9 读契约钉死：七槽位偏移、三类读法、haa 前向
兼容回退。op 封套读写全闭。纯文档+fixture 阶段。
