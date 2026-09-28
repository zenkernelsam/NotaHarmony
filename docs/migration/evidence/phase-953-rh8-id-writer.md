# Phase 953 — `rh8` 线协议三件套：qo5 写器/工厂 + closeFinally

来源：`decompiled_1.0.3/sources/defpackage/rh8.java`、`qo5.java`

## 1. `rh8` 分类

R8 混淆归并的巨型工具类（2370 行，~30 静态方法），主体为
Compose UI / XML 解析（`K`）/ 协程助手。**线协议相关仅三件套**：

## 2. `O(qo5, a)` — Id 8B 内联结构写器

```
short sC = qo5Var.c();    // site:UShort
int iD   = qo5Var.d();    // timestamp:UInt
aVar.t(4, 8);             // 开始 4 对齐 8B 内联结构
aVar.w(iD);               // timestamp 写 @4（先写高偏移）
aVar.s(2);                // 2B pad
aVar.y(sC);               // site 写 @0
return aVar.r();          // 结构偏移
```

逆序写入 → 布局 **`{site:short@0, pad@2, timestamp:int@4}`**。

## 3. `b(int, short) → qo5` — Id 工厂

```
a aVarA = dk4.a(c8dVar);
aVarA.t(4, 8); aVarA.w(i); aVarA.s(2); aVarA.y(s);
aVarA.p(aVarA.r());                     // finish root
qo5Var.b(rootOff, byteBuffer);          // 反读
ybg.c(qo5Var);                          // 校验（a()=null 恒过）
q(c8dVar, null);                        // closeFinally 归还
```

参数序 `b(timestamp:int, site:short)`（`w(i)`=int 先传）。

## 4. `qo5` = **`Id{site:UShort@0, timestamp:UInt@4}`**

- `c()` = `getShort(I)` → `ymf.a()` 格式化为 UShort
- `d()` = `getInt(I+4)` → `mmf.a()` 格式化为 UInt
- `toString` = `"Id(site=N, timestamp=N)"` 实证
- `equals/hashCode` = (d(),c()) 字段对
- 8B = **`cxc` SeqId 的前缀**（cxc 追加 index@8 = 12B 位置 ID）：
  - `qo5` = 实体 ID（op/ink/shape 等的 Lamport 时钟 ID）
  - `cxc` = 文本位置 ID（同 site+timestamp + 段内 index）

## 5. `q(AutoCloseable, Throwable)` — Kotlin `closeFinally`

- th!=null：`do6.x` 关闭并 `s01.h(th,th2)` addSuppressed
- th==null：直接 `close()`；ExecutorService 特判 shutdown+
  awaitTermination（协程调度器归并路径）

## 6. 附带位打包助手（非线型）

- `a(f,f)` = 两 float 打包 long（`f<<32|f&0xFFFFFFFF`）— 点坐标压缩
- `i(i,i)` = 两 int 打包 long

## 7. Harmony 对齐

`rh8.O`/`b` 的 qo5 布局与 `nti.X` cxc 写器同构（ID 家族：
qo5 8B ⊂ cxc 12B）。Harmony 侧 OriginalOperation 解码已按
{site:u16@0, timestamp:u32@4} 读（Replay 覆盖）；写侧保持同
逆序。`rh8.q` = Kotlin stdlib 语义，Harmony 用 `finally`/`using`
等价。

## 8. 验证

- `d02-rh8-id-writer.mjs` 静态断言。
