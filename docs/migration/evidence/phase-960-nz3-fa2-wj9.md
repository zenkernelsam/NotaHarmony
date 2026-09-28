# Phase 960 — 残余线协议助手：`nz3`/`fa2.w`/`wj9`/`qub.l`

来源：`decompiled_1.0.3/sources/defpackage/`{nz3,fa2,wj9,qub,uq9}.java

## 1. `nz3` — Kotlin **EnumEntries** 实现

```java
class nz3 extends y3 implements lz3, RandomAccess {
    Enum[] I;                     // 枚举数组
    d() = I.length;               // 大小
    get(i) = I[i];
    contains(o) = I[o.ordinal()] == o   // ordinal 快查
}
```

`haa.q0` = 该 EnumEntries 实例。`uq9.m()` payloadType 解码：

```java
int i = (b & 255) - (entries[0].I & 255);   // byte→ord 相对首序数
return (i<0 || i>=size) ? entries[0] : entries[i];
                                          // 越界 → NONE
```

**实证 Phase 905**：未知 payloadType 字节回退 NONE。

## 2. `fa2.w(num, yn7, str, exc)` — 负长日志助手

```java
a.c(yn7Var, str, exc, new lg5(0, num));
```

`lg5(0,num)` = 惰性消息λ（序号0 + 值）；线协议写器的
`"Got negative length"` 全经此路径。

## 3. `wj9` — R8 归并 Function1，元素提供器（case 9/10）

```java
case 9:  ((qub) K).l(((Number) obj).intValue(), (cxc) J); return cxc;
case 10: ((f2c) K).l(i, (cxc) J);                     return cxc;
case 7:  ((zgb) K).m((uq9) J, i);                     return uq9;
case 8/13: ((List) J).get(i) 索引包装...
```

`wj9(N, holder, table)` = **按 N 分派的表内零拷贝元素访问器**——
`vej.q` 的 `wj9(9, sg5.b(), qub)` = 池化 cxc 持有者 + qub 表：
逐索引 `qub.l(i, holder)` 就地初始化后交给 `sg5.f` 写入。
**零分配读取循环**。

## 4. `qub.l(int, cxc)` — 元素访问器细节

```java
iC = c(4);                        // locations 向量槽
iC==0 → h34.l("Index out of range: i, vector locations is empty")
iF = i*12 + f(iC);                // **12B 步长**元素偏移
cxc.b(iF, J);                     // 持有者定位
cxc 未返回新对象——就地初始化（返回 void）
```

`qub.toString` = `"RemoveChars(locations=" + lv2.N(this) +
", textField=" + k() + ")"` —— RemoveChars 再实证 + `lv2.N` 为
其物化器。

## 5. Harmony 对齐

- 元素访问器的"就地初始化持有者"模式 = 零 GC 设计；
  Harmony 可直接新建小对象或按同模式复用——等价。
- `nz3` EnumEntries 越界回退 = Harmony 解码器需镜像
  （unknown→NONE）；已在 OriginalOperation 解码断言中覆盖。

## 6. 验证

- `d02-nz3-fa2-wj9.mjs` 静态断言。
