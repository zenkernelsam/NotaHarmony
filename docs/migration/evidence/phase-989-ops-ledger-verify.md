# Phase 989 — `.ops`/`.offsets` 完整性校验链 + `z5c.i` + `uw7` 物化

来源：`decompiled_1.0.3/sources/defpackage/{nce,z5c,uw7,o76}.java`

## 1. `nce` 校验块（synced-ops 装载路径内）

依序校验（任一失败 → `n76`/`o76` 错误 → CorruptedSyncedOpException）：

```java
ops.exists() && ops.length() == pae.l            // 期望 opFileSize
offsets.exists()  else "offsets file not found"
offsets.length() == opCount * 4                  // int32 索引长度
z5c.i(ops) == pae.p                              // ops CRC32 vs opsChecksum
// offsets 原文 CRC32（crc33 累计整段 bytes）
per-offset:
  iZ < 0              → "negative offset at index"
  iZ >= ops.length    → "offset out of bounds"
  i==0 && iZ != 0     → "first offset must be 0"
  iZ <= prev          → "non-monotonic offset"
```

**五重校验**：size + 双 CRC32 + 逐偏移单调性。

## 2. `z5c.i(File)` = 文件 CRC32

64KB 块 BufferedInputStream 全程 `crc.update` →
`(int)getValue()`；不存在/空文件返回 0。

## 3. `uw7` = `.ops`+`.offsets` 物化器（读）

```java
if (pae.k == 0) → hw3.I
offsets.length() < k*4 → "Offsets file too short" + null
read last offset (seek (k-1)*4); ops.length < last →
  IOException("Ops file too short")
mmap .ops READ_ONLY → 逐 offset → LE uoffset → uq9.d
→ ArrayList(k)
```

## 4. `o76`/`n76` = 校验错误包装

`o76(msg)` = per-条目违例（negative/bounds/first≠0/
non-monotonic），`n76` = 结构性缺失（offsets not
found/长度不符）——最终汇入 CorruptedSyncedOpException
→ `ebe.J` 重下载路径（Phase 985 闭环）。

## 5. Harmony 对齐

等价：size+双 CRC32+单调性五重校验；违例走
corrupt→redownload 而非尝试修复。

## 6. 验证

`d02-ops-ledger-verify.mjs` 静态断言。
