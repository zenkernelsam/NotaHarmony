# Phase 957 — `nti` 线协议助手：cxc 工厂对 + LEB128 变长编码

来源：`decompiled_1.0.3/sources/defpackage/nti.java`、`iy0.java`

## 1. `nti` 分类

R8 归并巨型类（2999 行 ~50 静态），主体 Compose/UI；
**线协议与序列化相关成员**：

## 2. cxc/SeqId 写器 + 工厂对

```
X(cxc,a):  t(4,12) w(C=idx) w(d=ts) s(2) y(c=site) → r()
           // 与 sg5.f 逐字节一致（954）

f(short s, int i, int i2):           // f(site, timestamp, index)
  dk4.a(c8d)→t(4,12)w(i2)w(i)s(2)y(s)
  →p(r())→b()反读→ybg.c→rh8.q     // 标准工厂五步

g(qo5, i): f(qo5.c(), qo5.d(), i)    // 实体 Id + index → 位置 SeqId
```

**Id→SeqId 派生**：`g` 实证 `cxc` = `qo5` 扩 index——
文本位置 ID 由宿主实体 ID + 段内索引组成。

## 3. `n0`/`o0` — LEB128 变长编码对

```java
n0(baos, i):               // u32 LEB128
  require i>=0 ("Failed requirement.")
  while i>=128: write(128|(i&127)); i>>>=7
  write(i)

o0(baos, i):               // i32 zigzag-LEB128
  j2 = ((i>>31)^(i<<1)) & 0xFFFFFFFF   // zigzag
  while j2>=128: write(128|(127&j2)); j2>>>=7
  write(j2)
```

**protobuf 风格 varint**：`n0`=无符号，`o0`=zigzag 有符号。
唯一调用点 `iy0.a` = `bk_paths.append`——笔迹路径 blob 的
**自研二进制编解码**（非 FlatBuffer）。

## 4. `iy0` = bk_paths 追加器（预读，Phase 958 详表）

- `a(cxc, gy0, short s, int i, int i2, wx0)`：
  `n0` 路径数 → 每路径 `n0` 元素数 + **2bit 打包标志字节**
  （`f(i)&3` 凑 4 个一字节）→ 第二遍每点 `o0` zigzag
  **增量编码**坐标（`m18.y0(f*4096)` 定点量化，x/y 存于
  `idd` long 压缩对 `getLong(i*8)`：高 32=f32 x，低 32=f32 y）
- 1MiB blob 上限（"bk_paths.append blob exceeds cap"）
- `zeb.e(n, s, i, i2, j2, crc32)` = 索引记录头写入 fileD；
  blob 追加 fileA——**索引/数据分离双文件**
- `f(File,j)` = mmap READ_ONLY 只读映射
- 日志 `yn7.INK` "bk_paths.append ..."；IO 异常→`o=false`+
  `d.e(tz9)` 恢复事件

## 5. `j0(uq9)` = `"OpMetadata(op=N)"` 日志助手；
`p(i,i2,i3,str)` = 范围检查 `IllegalArgumentException
"...out of range of [i2,i3] (too low/high)"`。

## 6. Harmony 对齐

- cxc 写/工厂对与 sg5.f/rh8.O 同构（Replay 覆盖）。
- `n0`/`o0` LEB128 = 磁盘日志编码，**与 FlatBuffer 线格式无关**；
  Harmony 笔迹存储格式需等价实现（若走同格式）——见 Phase 958。
- `p` = Kotlin `require` 语义，直接等价。

## 7. 验证

- `d02-nti-wire-helpers.mjs` 静态断言。
