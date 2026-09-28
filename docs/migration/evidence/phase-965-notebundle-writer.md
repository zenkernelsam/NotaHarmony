# Phase 965 — `q4j.b` r29 **NoteBundle 写器**（线型根）

来源：`decompiled_1.0.3/sources/defpackage/q4j.java`

## 1. `b(r29,a)` — 入口

抽 9 访问器 → `c(...)`：`s29(r29,N)` 字符串λ 对（f3/f5）、
`q5(27, x82.x(sg5.n,OP_HOLDER), r29)` = op 元素提供器
（uq9 池化持有者 + 表）。

## 2. `c(a, utf,utf,short,CharSeq,long,CharSeq,int,ix4)` — 8 字段写器

```
// ops 向量（先序列化元素收集偏移）：
i<0 → "Got negative length"(MODEL, lg5(1,·))
i>=0:
  zCAS = sg5.e().compareAndSet(false,true);   // usingOffsetsHolder
  list = zCAS ? sg5.d() : sg5.c();            // 双缓冲偏移表
  list.clear();
  for i2 in 0..i: list.add(ree.a(ops[i2], a)) // 每 op 递归序列化
  aVar.D(4, i, 4);                            // uoffset 向量
  for i3=i-1..0: aVar.g(list[i3])             // 逆序推偏移
  vec = o();  zCAS → e().set(false)           // CAS 归还
  // ★ 嵌套写时第二个表用另一缓冲——重入安全

iC = dbj.c(editorUserId); iC2 = dbj.c(creatorUserId);
aVar.C(8);
h(6, opsVector)          // f6 ops<uq9>
j(0, zwd.a(noteId))      // f0 utf 16B struct
if (legacyId) j(1, zwd.a(legacyId))
i(2, editorSite)         // f2 short
h(3, iC)                 // f3 editorUserId
f(4, createdAt)          // f4 long
h(5, iC2)                // f5 creatorUserId
i(7, rgc.a)              // f7 schemaVersion = rgc.a 常量
iN = n();
z(iN,4); z(iN,10); z(iN,14)   // required: f0 noteId + f3 + f6 ops
```

## 3. 读写镜像终证（Phase 906 读侧）

| f | 读 c() | 写 | required |
|---|--------|-----|----------|
| 0 noteId utf | c(4) | j(0) | **z(4)** ✓ |
| 1 legacyNoteId | c(6) | j(1) opt | |
| 2 editorSite | c(8) | i(2) | |
| 3 editorUserId | c(10) | h(3) | **z(10)** ✓ |
| 4 createdAt | c(12) | f(4) | |
| 5 creatorUserId | c(14) | h(5) | |
| 6 ops vector | c(16) | h(6) | **z(14)** ✓ |
| 7 schemaVersion | c(18) | i(7)=rgc.a | |

## 4. 关键细节

- `ree.a` 逐 op 序列化 + **CAS 双缓冲**处理 op 内嵌向量
  写时的偏移收集重入
- `sg5.n` = OP_HOLDER 池（uq9）
- `rgc.a` = 当前 schema-version short 常量（ar6 系，~15）

## 5. Harmony 对齐

Harmony `encodeOriginalNoteBundle` 字段序/三 required 已对齐
（906 Replay）；**嵌套偏移收集重入语义** = 写器内部细节，
Harmony 等价实现仅需正确性。

## 6. 验证

- `d02-notebundle-writer.mjs` 静态断言。
