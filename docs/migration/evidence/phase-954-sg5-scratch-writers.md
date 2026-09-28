# Phase 954 — `sg5` 草稿池写侧：`f` cxc 写器 + `g` 元素提供器

来源：`decompiled_1.0.3/sources/defpackage/sg5.java`、`exc.java`、`wj9.java`

## 1. `sg5` 池结构（Phase 944 已见持有者名，本 Phase 全量）

`fl6[] a` 13 委托属性（Kotlin 属性名实证真实 Kotlin 名）：

| # | 属性名 | 池 | 类型 |
|---|--------|-----|------|
| 0 | `offsetsHolder` | c | List |
| 1 | `nestedOffsetsHolder` | d | List |
| 2 | `usingOffsetsHolder` | e | AtomicBoolean |
| 3 | `ID_HOLDER` | f | **Id=qo5** |
| 4 | `SEQ_ID_HOLDER` | g | **SeqId=cxc** |
| 5 | `STYLE_MAP_HOLDER` | h | **StyleMap=yyd** |
| 6 | `RECORDING_SEGMENT_PROVIDER` | i | **RecordingSegment=ukb** |
| 7 | `POINT_HOLDER` | j | **Point=fqa** |
| 8 | `SIZE_HOLDER` | k | **Size=qed** |
| 9 | `MODIFY_POSITION_HOLDER` | l | **ModifyPosition=ie8** |
| 10 | `DUPLICATE_OP_HOLDER` | m | **DuplicateOp=xq3** |
| 11 | `OP_ACK_HOLDER` | n | **OpAck=vq9** |
| 12 | `OP_HOLDER` | （无字段池） | **Op=uq9** |

`cz8(factoryλ, x97(26))` = 容量 26 的对象池；
`x82.x(pool, prop)` = 属性委托 acquire；`b` = ThreadLocal；
`o` = `d1.W` = 空元素提供器哨兵（vej.q 空向量路径）。

## 2. `f(a, exc) → int` — **cxc/SeqId 12B 内联写器**

```
short sM = excVar.m();   // site
int iA1  = excVar.a1();  // timestamp
int iC   = excVar.C();   // index
aVar.t(4, 12);           // 4 对齐 12B 内联
aVar.w(iC);              // index   @8
aVar.w(iA1);             // timestamp @4
aVar.s(2);               // pad 2B
aVar.y(sM);              // site    @0
return aVar.r();
```

**与 `nti.X` 逐字节一致**（Phase 945 实证 cxc 读侧布局
`{site:short@0,pad@2,ts:int@4,idx:int@8}`）——`sg5.f` 就是
向量元素的规范 cxc 写器，所有 `x[]` 向量（locations/members/
tombstones）共用。

## 3. `exc` — SeqId **Comparable 接口**

```
int C();      // index
int a1();     // timestamp
short m();    // site
default A0(exc): compareTo
  = a1()差 → m()&0xFFFF 差 → C()差
```

**CRDT 位置排序 = timestamp → site → index**（Lamport 优先于
site 的字典序）——文本位置的全序由该默认方法给出，cxc 实现之。

## 4. `g(List) → ix4` — 元素提供器工厂

`list==null||isEmpty → o(d1.W)`；否则 `new o1(list)`。
与 `wj9`（表内向量提供器，`new wj9(9,scratch,table)`）配对：
- `wj9` = 读表型提供器（按索引调表访问器）
- `o1` = 列表包装提供器（`list.get(i)`）
- `d1.W` = 空哨兵

工厂/写器对以此分流：工厂持 list→o1；写器持 table→wj9。

## 5. Harmony 对齐

cxc 写侧逆序与读侧布局等价（Replay 945 覆盖）；
`exc.A0` 排序语义 = timestamp>site>index，Harmony
OriginalOperation 的位置比较应镜像该全序——Replay 断言。

## 6. 验证

- `d02-sg5-scratch-writers.mjs` 静态断言。
