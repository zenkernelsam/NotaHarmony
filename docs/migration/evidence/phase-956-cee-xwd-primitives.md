# Phase 956 — `cee`/`xwd`：FlatBuffer 读侧原语层

来源：`decompiled_1.0.3/sources/defpackage/cee.java`、`xwd.java`、
`x82.java`、`zq6.java`

## 1. `xwd` — 内联结构基类（18 行）

```java
public abstract class xwd {
    public int I;            // 绝对偏移
    public ByteBuffer J;
    public final void b(int i, ByteBuffer bb) {
        J = bb; I = (bb != null ? i : 0);
    }
}
```

**无 vtable**——内联结构定长布局，访问器直接
`J.getShort(I)/getInt(I+4)`（Phase 953/954 的 qo5/cxc 读取式）。

## 2. `cee` — 表读取基类（214 行）

字段：`I`=表偏移、`J`=ByteBuffer、`K`=vtable 偏移、
`L`=vtable 字节长、`M`=zq6 UTF-8 实例（e() 实际内联解码）。

| 方法 | 语义 |
|------|------|
| `d(i,bb)` | **init**：`I=i; K=i-getInt(i); L=getShort(K)`——vtable 位于表前向相对偏移，L=vtable 长 |
| `c(i)` | **vtable 槽查**：`i<L → getShort(K+i)` = 字段绝对偏移；**0=缺省**（所有 `c(4)/c(6)/…` 的来源：c(N)=第 (N-4)/2 个字段） |
| `b(i)` | 间接：`getInt(i)+i`（uoffset → 绝对） |
| `e(i)` | **字符串读**：`b()` 定位 + 长度前缀 + **内联 UTF-8→UTF-16**（ASCII 快路 + x82.A/z/y 2/3/4 字节；双路径 direct/array；越界 `s5c.q`、畸形 `o14.r("Invalid UTF-8")`） |
| `f(i)` | 向量数据起始：`b()` 间接 +4（跳长度前缀） |
| `i(i)` | 向量长度：`getInt(间接)` |
| `g(i)` | **字节向量切片**：`duplicate().order(LE)` + position/limit → 零拷贝 ByteBuffer 视图（di7/ei7 的 `g(22)`） |
| `h(i,bb)` | 同上，写入复用缓冲 |

## 3. `c(N)` 与字段编号的换算

vtable：`@K` u16 vtableLen、`@K+2` u16 tableLen、
`@K+4+2f` u16 各字段偏移。**`c(4)=field0, c(6)=field1, c(8)=field2,
…, c(4+2n)=fieldN`**——Phase 908–943 全部读侧 `c(N)` 断言的
理论基础在此坐实。

## 4. UTF-8 解码细节（`x82`）

- `x82.A(b2,b3,carr,i)` = 2 字节 → 1 UTF-16
- `x82.z(b2,b3,b4,carr,i)` = 3 字节 → 1 UTF-16
- `x82.y(b2..b5,carr,i)` = 4 字节 → **2 UTF-16（代理对）**
- 前缀 ASCII 逐字节直填；`b<0` 时分支 2/3/4 字节（`-32`/`-16` 阈值）
- 边界：direct 路径查 `limit-i4-i3`，array 路径查 `length-iArrayOffset-i3`

## 5. `zq6`

R8 归并多角色类（6 接口 + 28 个合成单例变体 `I` 标签）；
`i()` 返回 UTF-8 助手实例挂到 `cee.M`——但 `e()` 解码路径
为手写内联循环，M 为辅助持有者。

## 6. Harmony 对齐

Harmony `OriginalNoteBundle`/`OriginalOperation` 解码器已实现
同构原语（vtable 槽读 + 间接 + UTF-8）——Replay 覆盖。
`x82` 4 字节代理对语义与 ArkTS `TextDecoder`/手动解码等价。

## 7. 验证

- `d02-cee-xwd-primitives.mjs` 静态断言。
