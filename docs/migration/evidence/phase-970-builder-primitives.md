# Phase 970 — `com.google.flatbuffers.a` 写侧原语全图

来源：`decompiled_1.0.3/sources/com/google/flatbuffers/a.java`

R8 混淆版 FlatBufferBuilder——方法名单字母，语义与原库
一致；本次逐一钉死全部原语。

## 1. 字段

| 字段 | 原库名 | 语义 |
|------|--------|------|
| `a` | bb | ByteBuffer（LITTLE_ENDIAN） |
| `b` | space | 头指针（capacity-b = offset） |
| `c` | minalign | 默认 1 |
| `d` | vtable | 当前表槽偏移数组 |
| `e` | vtable_num | 槽数 |
| `f` | nested | 嵌套写禁止标志 |
| `g` | finished | finish 后可取 |
| `i` | vtables | vtable 去重暂存 |
| `j` | num_vtables | 已写 vtable 数 |
| `k` | vector_num_elems | 当前向量计数 |
| `l` | forceDefaults | **强制写默认值标志** |
| `m` | allocator | `ldj`/`c8d` 分配器 |
| `n` | （zq6 助手实例） | 内部 utf8 等 |

## 2. 标量字段写（默认值省略 + l 旁路）

```
a(i,z,z2)  bool   : if (l || z != z2)  { t(1,0); put; B(i) }
d(i,f,d)   float  : if (l || f != d)   { t(4,0); v(f); B(i) }
e(i,i2,i3) int    : if (l || i2 != i3) { t(4,0); w();  B(i) }
f(i,j)     long   : if (l || j != 0)   { t(8,0); x(j); B(i) }
i(i,s)     short  : if (l || s != 0)   { t(2,0); y(s); B(i) }
c(i,b,i2)  byte   : 同上
```

**`l`（forceDefaults）= setter 写器的强制写标志**：
`l=true` 时即便值==默认也落盘——三态写语义硬件层。

## 3. 偏移/结构字段

```
g(i)   putOffset: w((r()-i)+4)   // rel uoffset
h(i,x) addOffset: if (l||x!=0) { g(x); B(i) }
j(i,x) addStruct: if x==r() B(i) else "must be serialized inline"
B(i)   slot: d[i] = r()
```

## 4. 表/向量/结构生命周期

```
C(i)  startTable: nested→o14.i 报错; d[]=新/复用; e=i; 清零; f=true; h=r()
D(size,cnt,al) startVector: t(4,size*cnt); t(al,size*cnt); k=cnt; f=true
o()   endVector: !f→报错; f=false; w(k); r()
n()   endTable: soffset 占位 w(0) → vtable 尾零裁剪
      (while d[i2]==0 i2--) → 逐槽 y(off) → y(objSize)
      → y(vtSize=(i2+3)*2) → i[]/j vtable 去重 → 写回
t(a,s) prep; s(i) pad×i; r() = capacity-b
p(i)  finish: t(c,4); g(i); position(b); g=true
q()   未 finish 取缓冲 → o14.i 报错
A()   sizedByteArray: q() 后复制 [b..capacity)
z(i,i2) required: getShort(tableAbs-soffset+i2)==0 →
      o14.i("FlatBuffers: field "+i2+" must be set")
```

## 5. 构造

```
a()                       : this(1024?, bk4.R, null, zq6.i())
a(c8d, ByteBuffer)        : this(cap, c8d, bb, zq6.i())  ← dk4 池化路径
a(int, ldj, bb, zq6)      : bb 复用 clear()+LE 或 m.l2(i) 分配
```

## 6. 结论

- 写侧原语 = 原版 FlatBuffers 语义 1:1（vtable 尾零裁剪、
  去重、required 槽检查、默认值省略、forceDefaults 旁路）。
- `l` 标志实证 setter 三态写的底层机制（Phase 966）。

## 7. Harmony 对齐

Harmony `encode.ts` 系自研等价 builder——vtable 裁剪/去重/
required 语义须与原版逐字节一致；此表为核对清单。

## 8. 验证

`d02-builder-primitives.mjs` 静态断言。
