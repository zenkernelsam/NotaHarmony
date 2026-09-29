# Phase 983 — Client-Ops WAL 文件格式（写 `ky`↔读 `fr1`）

来源：`decompiled_1.0.3/sources/defpackage/{ky,nr1,fr1,hr1}.java`

## 1. 写路径 `ky` case 1（`nr1` 委托）

```java
File dir = ((nr1) this.J).d.a();            // qr1 WAL 目录
for (List<uq9> batch : au1.R0(ops, 100000)) {// 10 万/批分块
    name = noteId + "-" + nanoTime + "-"
         + nr1.s.incrementAndGet() + "-" + i + ".wal";
    tmp  = name + ".tmp";
    DataOutputStream out = ...(BufferedOutputStream(FileOutputStream(tmp),8192));
    out.write(ttf.a());                     // 16B noteId
    out.writeInt(list.size());              // BE int 计数
    for (uq9 op : list) {
        byte[] b = ree.b(op);               // 完整 op 信封
        out.writeInt(b.length);             // BE int 长度前缀
        out.write(b);                       // LE FlatBuffer 负载
    }
    out.close();
    fag.m0(tmp, wal);                       // .tmp→.wal 原子改名
}
```

- IOException → `LOCAL_PERSISTENCE` 日志 + 删 tmp。
- Throwable → 删全部已产 WAL 后重抛（失败不残留）。

## 2. 读路径 `fr1` case 0（`nr1.h(file)` 分发）

```java
byte[16] readFully → m18.X = ttf noteId
int count = readInt();  // guard: 0 ≤ n < 100001 → else "WAL op count out of range"
per op:
  int len = readInt();  // guard: 1 ≤ len < 10485761(10MiB) → "WAL op size out of range"
  total += len;         // guard: total ≤ 524288000(500MiB) → "WAL total size exceeded"
  readFully(buf) → LE ByteBuffer → uq9.d(pos+uoffset)   // 信封根读
return k1a(o69(noteId), ops)
```

`fr1` case 1 = `file.delete()`（WAL 消费后删除协程）。

## 3. 格式要点

- **框架 BE**（DataStream writeInt/readInt）包裹 **LE FlatBuffer** 负载——
  双端序混合格式。
- 三道 fail-closed 上限：批 ≤100000、单 op <10MiB、总 ≤500MiB。
- `hr1` = FilenameFilter 合并类：case0 `.tmp`、case1 `.wal`、
  case2 `aqs.`、case3 `.ae`、case4 `event`——WAL 目录扫描。
- `nr1`：`s`=AtomicLong WAL 序号，`r`=30s 提交超时
  （"Client ops WAL commit took too long" 告警），
  Room invalidation 监听 ClientOp/DraftNote。

## 4. 与 Room 的关系

WAL 是**落盘队列**（原子改名保证 crash 安全），ClientOp
表是索引视图；提交路径 `nr1.b` = 写 WAL→入库→删 WAL
（详见 `nr1.b` 协程状态机）。

## 5. Harmony 对齐

等价语义：长度前缀+原子改名+三档上限校验+消费后删除。

## 6. 验证

`d02-wal-format.mjs` 静态断言。
