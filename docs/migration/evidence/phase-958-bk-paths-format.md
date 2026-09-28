# Phase 958 — `bk_paths` 笔迹 blob 磁盘格式全解

来源：`decompiled_1.0.3/sources/defpackage/iy0.java`、`zeb.java`、
`zx0.java`、`gy0.java`、`nti.java`（957）

## 1. 文件布局

```
<root>/bk_paths/<noteId-uuid>/          zx0.e(ttf)
    <pageId>.dat                        zx0.a  — 追加式 blob 数据
    <pageId>.idx                        zx0.d  — 24B 定长索引记录
```

pageId 文件名 = `ldj.r2(cxc)`；日志中的格式
`%04x-%08x-%08x` = **{site:hex4}-{timestamp:hex8}-{index:hex8}**。

## 2. `iy0.a` = `bk_paths.append` 写入路径

```
gy0.b = 当前 dat 尾偏移（>Int32 记 "offset exceeds Int" 拒绝）
y64.reset();
n0(y64, list.size());                   // varint 路径数
for path in wx0.a (List<l8a>):
    n0(y64, l8a.b.b);                   // varint 元素数
    // 元素标志 2bit 打包：f(i)&3 累加，每 4 个凑满 1 字节
    //   i7+=2；i7==8 时 write(iF)；循环尾 i7>0 补写残字节
for path again:                         // 第二遍写点坐标
    for point in l8a.a (idd):
        j = idd.a[i] 或 bb.getLong(i*8) // long 压缩对
        x = intBitsToFloat(j>>32)*4096  // 高32=f32 x
        y = intBitsToFloat(j&0xFFFFFFFF)*4096
        o0(y64, y0(x)-i14); o0(y64, y1(y)-i15)  // zigzag 增量
blob = y64.a()[0..b());
>1MiB → "blob exceeds cap" 拒绝；offset+size 溢出同拒
crc32.reset+update(blob)
zeb.e(this.n, s, i, i2, j2, crc);       // 组 24B 索引头
FileOutputStream(fileD,append).write(n) // 先 idx
FileOutputStream(fileA,append).write(blob) // 后 dat
gy0.b = j2+size
IOException → this.o=false + d.e(tz9)   // 强制重建路径
```

## 3. `zeb.e` — 24B **大端**索引记录

```
[0:2)  site u16 BE     [2:4)  0x0000
[4:8)  i   int BE      [8:12) i2  int BE
[12:20) j   long BE    (dat 内偏移)
[20:24) i3  int BE     (CRC32)
```

**手工移位 BE**——与 FlatBuffer LE 线格式相反；
纯字节序外无标记/版本。

## 4. `iy0.d` = `bk_paths.ensureMmapCovers` 读路径

- `gy0` = 页状态 `{ck8 a, long b=datSize, ByteBuffer c=mmap}`
- `f(File,j)` = `RandomAccessFile`+`FileChannel.map(READ_ONLY)`
- mmap 缓存于 `gy0.c`，旧映射 `qf3.a` 释放
- 失败日志 `ep7.L`+`yn7.INK`：`note.id` + `page.id`(%04x-%08x-%08x)

## 5. 配套类型

- `l8a` = `{a:idd 点列, b:标志列}` 单路径
- `idd` = 点存储：`a`=long[]（×64 位压缩对）或 `b`=offHeap
  ByteBuffer（`getLong(i*8)`），`d`=倒序标志，`e`=计数
- `wx0` = `{a:List<l8a>}` 页内路径集合
- `gy0`/`ey0{i,cxc}`/`ck8` LRU 缓存 = 页/段缓存层
- `y64` = ByteArrayOutputStream 变体（reset/a/b）

## 6. Harmony 对齐

- **自研二进制磁盘日志**，与 FlatBuffer 线格式无关。
- Harmony 若沿用同格式可复刻：LEB128、2bit 打包、zigzag
  增量、×4096 量化、CRC32、24B BE idx——全部平台无关。
- mmap 读：Harmony 可直接文件读或 `@kit.CoreFileKit` 映射；
  `qf3.a` unmap 在 ArkTS 无需处理（GC 管理）。

## 7. 验证

- `d02-bk-paths-format.mjs` 静态断言。
