# Phase 893 证据 — `cee`/`xwd` 读侧基类原语

## 目的

实名全部 reader 依赖的读侧基类（与 892 写侧对称）。
`decompiled_1.0.3`。

## `cee` = 生成代码 Table 基类

```java
public int I;              // bb_pos：表位置
public ByteBuffer J;       // bb
public int K;              // vtable 起点 = i - getInt(i)
public int L;              // vtable 长度 = getShort(K)
public final zq6 M;        // UTF-8 解码器单例
```

| 方法 | 语义 | 实现 |
|------|------|------|
| `b(i)` | **间接偏移**：UOffsetT→绝对位置 | `getInt(i)+i` |
| `c(i)` | **vtable 槽查**：`i<L ? getShort(K+i) : 0` | 缺字段→0 |
| `d(i,bb)` | **__assign**：I=i, K=vtStart, L=vtLen | 三字段装配 |
| `e(i)` | **__string**：UOffsetT→长前缀 UTF-8 | ASCII 快路径+zq6 |

- **`c(4+2·字段号)`** = 字段槽位读——与写侧
  `z(off,4+2·字段号)` required 标记**双向一致**：
  每 accessor 的 `c(4)/c(6)/c(14)` 即 field0/1/5。
- `e(i)` 字符串：长度前缀 + ASCII 逐 char 快路径 +
  `s5c.q` 越界失败消息 + `zq6` 解码器慢路径。

## `xwd` = Struct 基类（内联，无 vtable）

```java
public int I;              // 位置
public ByteBuffer J;
b(i,bb)：I=i（结构直接内联定位）
```

- cee 读路径 = I+槽偏移定位字段；xwd = I 直接定位成员。
- 15 个内联值类型（862）全部经 `xwd.b` 装配。

## Harmony 侧

`OriginalFlatBufferTableReader` 的 vtable 槽查/间接偏移/
字符串解码 = cee 原语逐方法对应；内联结构读 = xwd.b；
`I/J/K/L` 四状态 ↔ Harmony reader 位置模型。

## 结论

读侧基类实名：cee=Table（vtable+字段槽）、xwd=Struct
（内联）。`c(4+2i)` 公式与写侧 required 双向验证——
wire 层读写原语全部闭合。纯文档+fixture 阶段。
