# Phase 862 证据 — 内联结构层（xwd）与校验驱动器（ybg.c）登记 + tdf 形状核验

## 目的

FlatBuffer 线层闭卷收尾：登记 `xwd` 内联结构基座与其 15 个成员、
`ka4` 校验驱动器 `ybg.c`，并核验 `tdf`（type-26）与 Harmony
编码器的逐字节形状一致性（860 阶段曾标记为待核实项）。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `xwd` — 内联结构基座（区别于 `cee` 表基座）

```java
public abstract class xwd {
  public int I;            // 直接偏移
  public ByteBuffer J;     // 缓冲区
  public final void b(int i, ByteBuffer) // 无 vtable，固定偏移绑定
}
```

**15 个子类**：`utf`（Uuid 16B）、`qo5`（Id 8B）、`cwb`、`ua0`、
`fqa`、`ukb`、`cxc`、`xq3`、`bmb`、`v01`、`hu1`、`vy7`、`hd1`、
`yyd`、`qed` —— 颜色/坐标/变换等内联值类型，作为表字段的
定长内联存储（vtable 标记为 struct，读时不走偏移间接）。

### `ybg` — ka4 校验驱动器

```java
public static final void c(ka4 v) {
  String s = v.a();
  if (s == null) return;
  d(s); throw null;   // d(): a.c(MODEL, s) + throw new ValidationException(s)
}
```

`zq9.a()`（Op 信封读取入口）在 `uq9Var.d(...)` 后立即调用
`ybg.c(uq9Var)` —— **解析后即校验**，校验失败抛
`ValidationException`（`core/flatbuffers` 包内唯一存活类）。

### `tdf` — TransientInteractionEnded（type-26 负载）

| 字段 | 访问器 | 类型 | 语义 |
|------|--------|------|------|
| 0 | `l()` | `qo5` required | interactionId（缺则 `o14.i` required 门） |
| 1 | `k()` | `qo5` 可空 | replacedByOp（瞬态被何操作取代） |

### 序列化管道补充

- `ree.a`：IdentityHashMap 类→序列化 lambda 派发（`z0c(24)` 构建），
  `b()` 为独立表→bytes 入口；未知类 `rgc.b` 抛。
- `rh8.O`：qo5 Id 内联写入；`qqi.d`：sdf 瞬态标记写入；
  `z5c.x`：Op.payload 间接解引用；`dk4`/`c8d`：字节输出流封装。

## Harmony 核验（`OriginalTransientInteractionPayloadEncoder.ets`）

```ts
const table: number = 16;
const bytes = new Uint8Array(36);
writeVtable(bytes, 4, 20, [4, replacedByOp === null ? 0 : 12]);
writeU32(bytes, table, table - 4);
writeIdentity(bytes, table + 4, interactionId);        // id@0 必填 8B
if (replacedByOp !== null)
  writeIdentity(bytes, table + 12, replacedByOp);      // @1 可空 8B
```

**逐字节一致**：36 字节 = vtable(4+2×2) + sstart + table(16B 对象 =
vtable-offset 4B + id 8B + replacedByOp 8B)；vtable presence 槽
`[4, 0|12]` 与原版 required/可空语义完全对应。860 标记的形状疑点
已消除 —— 无缺口。

## 结论

- `xwd` 15 内联结构登记：Harmony 编码器以 `writeIdentity`/
  `readInlineBytes` 等定长读写等价覆盖（`qo5`=site u16+ts u32 8B、
  `utf`=Uuid 16B 已核）。
- `ybg.c` 校验驱动 = 「解析→ka4.a()→ValidationException」契约；
  Harmony 在解码器字段门处 throw —— 同位置 fail-closed。
- `tdf` 形状核验通过；序列化管道辅助类（ree/rh8/qqi/z5c/dk4/c8d）
  登记为运行管道，无独立契约。
- 本阶段纯文档+fixture，无源改动。
