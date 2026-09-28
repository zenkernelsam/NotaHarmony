# Phase 979 — 笔记 blob 加载路径（qud/uae/ba6.w/lv2.T）

来源：`decompiled_1.0.3/sources/defpackage/{qud,zac,uae,nce,ba6,lv2}.java`

## 1. `qud` = mmap 化笔记 blob 容器

```java
final class qud extends zac /*Closeable*/ {
    MappedByteBuffer J;   // r29 线型字节
    int K; long L;        // 版本/时标元数据
    File M;               // 底层文件
    boolean N;            // 保留标志
    a() { if (!N) M.delete(); }   // 默认关闭即删
}
```

`zac` = Closeable 基类 + `AtomicBoolean I`。

## 2. 加载链（nce 同步存储内，L2690+）

```java
qud qudVar = (qud) objO;                 // mmap blob
r29 r29VarN = uhj.n(qudVar.J);           // 根读入口
uae uaeVar = new uae(r29VarN);           // 视图包装
pae paeVarW = w(r29VarN);
// ★ 版本闸：u16 无符号比较
if (ba6.w(uaeVar.b() & 0xFFFF, rgc.a & 0xFFFF) > 0) {
    // bundle.schemaVersion > 当前 → 更新文件，走服务端
    // 迁移/拒绝路径（StaleSyncedNoteException 族）
}
... r3.u(ttf, uaeVar, qud.L, qud.K, paeVarW, ...) ...
List listT3 = lv2.T(r29Var2);            // ops 物化
```

## 3. `ba6.w(int,int)` = Integer.compare

`uae.b()&0xFFFF` vs `rgc.a&0xFFFF`——**u16 无符号**
schemaVersion 比较：bundle 更新（>0）→ fail-closed
走服务侧迁移，不静默截断。

## 4. `lv2.T`/`U` = ops 向量物化器

```java
T(r29): for i<p(): uq9 u=new uq9(); r29.r(u,i); add(u)
U(vt9): 同构（OpsBundle.j()/l()）
// m18.S() 构建 + m18.E() 冻结 + hw3.I 空哨兵
```

## 5. `jwh`/`nce` 上下文

`nce` = 同步笔记存储（NoteBundleMetadataDatabase +
`StaleSyncedNoteException`/`CorruptedSyncedOpException`）；
`jwh.a(...)` = 延迟 ops 文件读（"Skipping unreadable
deferred ops file"）——note = 主 blob + 延迟 ops 分段。

## 6. Harmony 对齐

mmap→根读→版本闸→物化链 = Harmony
`loadNote` 同构（既有 Replay 覆盖 u16 版本比较）。

## 7. 验证

`d02-blob-load-path.mjs` 静态断言。
