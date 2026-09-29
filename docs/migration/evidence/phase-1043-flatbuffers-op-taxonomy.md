# Phase 1043 证据 — FlatBuffers Table 基类 + 32 操作类型全集 + 接口层

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `cee` = FlatBuffers Table 基类（vtable 间接）

```java
public abstract class cee {
    public int I;            // table 起始 offset
    public ByteBuffer J;
    public int K;            // vtable offset = I - getInt(I)
    public int L;            // vtable 长度
    public final zq6 M;      // UTF-8 charset 持有
    public final int b(int i) { return J.getInt(i)+i; }        // uoffset 间接
    public final int c(int i) {                                 // vtable 槽查
        return i < L ? J.getShort(K+i) : 0;
    }
    public final void d(int i, ByteBuffer bb) {                 // table 绑定
        I=i; K=i-bb.getInt(i); L=J.getShort(K);
    }
    public final String e(int i);  // 内联 UTF-8 解码（x82.A/z/y 代理对）
}
```

对照 `xwd` = **Struct** 基类（固定布局，无 vtable，`b(i,bb)` 直绑）。

## `haa` = 操作类型全集（32 值，byte 0–31）

```
NONE=0  SET_METADATA=1  ASSET_CLOUD_PERSISTED=2  CREATE_PAGE=3
MODIFY_PAGE=4  CREATE_RECORDING=5  MODIFY_RECORDING=6
INSERT_CHAR=7  INSERT_STRING=8  REMOVE_CHAR=9  REMOVE_CHARS=10
REVIVE_CHARS=11  MODIFY_STYLE=12  MODIFY_PARAGRAPH_STYLE=13
CLEAR_STYLE=14  CREATE_INK=15  ADD_PATH_ELEMENTS=16  MODIFY_INK=17
CREATE_SHAPE=18  MODIFY_SHAPE=19  CREATE_GROUP=20  MODIFY_GROUP=21
CREATE_BLOCK=22  MODIFY_BLOCK=23  MODIFY_POSITIONS=24
DELETE_ENTITIES=25  TRANSIENT_INTERACTION_ENDED=26
MODIFY_PDF_FIELD=27  UPDATE_CHECKBOX=28  PEER_INTERACTION=29
CREATE_COMMENT=30  MODIFY_COMMENT=31
```

- `haa.I` = byte wire 码；`p0` = values 数组；`q0` = `nz3`
  （Kotlin EnumEntries）。
- byte→haa 越界→NONE 回退见 Phase 995（`uq9.m()`）。

## 接口层

- `ye9` = bundle 头 6 访问器 iface（a/b/c/d/e/f —— 对应 ze9 实现，
  Phase 1039 映射已证实）。
- `ka4` = 单方法 `String a()` iface（所有 FlatBuffer id 实现）。
- `exc extends Comparable` = pageId 排序 iface：`{a1()→int,
  m()→short, C()→int}`，默认 `A0` 比较序 = a1 → (m&0xffff) → C
  （先 site 类字段、再无符号 short、最后页序）。

## HarmonyOS 决策

- Table/Struct 双基类语义保留：vtable 间接 vs 固定布局。
- 32 操作类型全集建立 `OpType` 枚举映射，wire byte 一致。
- `exc.A0` 三键排序（a1→m→C）保留，注意 m 为无符号 short。

## 产出

- fixture `d02-flatbuffers-op-taxonomy.mjs`（12 断言）。
- ADR-0987；中文报告。
