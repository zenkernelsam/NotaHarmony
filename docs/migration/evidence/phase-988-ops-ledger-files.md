# Phase 988 — `.ops`/`.offsets`/`.fingerprints` 落盘账簿 + `kl1` CRC32 流

来源：`decompiled_1.0.3/sources/defpackage/{dbe,pr1,lv2,kl1,hg4}.java`

## 1. `dbe` = 同步文件路径提供者（`nce.a`）

| 方法 | 路径 | 内容 |
|------|------|------|
| `b()` | `<notesDir>`（`pr1(1)`=`context.getDir("notes",0)`） | 基目录 |
| `d(ttf)` | `<base>/<noteId>.ops` | **op 流文件**（拼接 uq9 根 buffer） |
| `c(ttf)` | `<base>/<noteId>.offsets` | **int32 偏移索引**（每 op 4B） |
| `a(ttf,row)` | `<deferredDir>/<noteId>/<row>.deferred` | deferred blob |
| `q(file,ttf,site)` | `<base>/fingerprints/<noteId>/<site>.fingerprints` | 站点指纹文件 |

`pr1`：0→`client_ops_wal`、1→`notes` 基目录、
2→`deferred` 子目录（WAL 目录同源确认）。

## 2. `lv2.s0(dbe,ttf,pae)` = 指纹账簿重建

```java
if (pae.k == 0) { tf4.u0(o0(...)); return 清零pae; }
opsFile = mmap(.ops, READ_ONLY)
offsets = RandomAccessFile(.offsets,"rws"?) 
loop i<pae.k:
  offsets.readFully(bArr, 0, min(rem,4K)*4)   // 分批读 int32
  pos = fsi.Z(bArr, i*4)                     // int32 偏移
  map.position(pos); LE; root uoffset
  slot8 → tmf = serverTime (long)
  slot4 → id: required; led(site)=short@i7, l3f(ts)=int@i7+4
  grouped[led(site)] += k1a(l3f(ts), xgb(serverTime))
per site:
  file = <site>.fingerprints;  fsi.z 父目录
  kl1 = CRC32 BufferedOutputStream(file)
  per op: LE 12B record {ts:int32, serverTime:int64}
  hg4(site, fileLen, kl1.a())  // kl1.a()=流 CRC32
→ LinkedHashSet<hg4>  // 入 SyncedOpMetadata 行
```

## 3. `kl1` = CRC32 计数流

`extends il1`（zd5.a()=(int)J.getValue()）；
三个 write 重载均 update CRC——写指纹文件同时得
校验和，无需二次扫描。

## 4. `hg4` = FingerprintFileLength

`{siteId:short, length:int, checksum:int}`，toString
实证列名对应 SyncedOpMetadata.fingerprintFileLengths
+ offsetsChecksum/opsChecksum 同族指纹体系。

## 5. `lv2.p` / `o0` / `q`

- `o0(base,ttf)` = `<base>/fingerprints/<noteId>`。
- `q(...,site)` = `<site>.fingerprints`（`ymf.a(site)`）。
- `p(file,sites)` = 按现存 site 集合清理指纹目录孤儿。
- `lv2.t(q89)` = OpAck 向量物化器（补齐 lv2 族）。

## 6. 语义

**op 账簿三层**：`.ops`（原始字节流）+ `.offsets`
（int32 随机访问索引）+ `fingerprints/<site>.fp`
（每站点 {ts,serverTime}×N + CRC32+length 指纹入库）
——服务端对账校验载体。

## 7. Harmony 对齐

等价：三层账簿 + LE 12B 指纹记录 + CRC32 流式写 +
site 分组指纹入库。

## 8. 验证

`d02-ops-ledger-files.mjs` 静态断言。
