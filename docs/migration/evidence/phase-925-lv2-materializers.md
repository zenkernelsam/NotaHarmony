# Phase 925 证据 — `lv2` 物化器族（向量→List）

## 目的

各表 toString/校验共用的 `lv2.*` 静态族实名——
FlatBuffers 向量 → Kotlin List 的统一物化层。

## 物化器注册表

| 方法 | 宿主表 | 语义 |
|------|--------|------|
| `A/B/D/E/G(dm2)` | CreateInk | 路径向量物化 |
| `C/F(wd8)` | ModifyInk | 路径向量物化 |
| `M(wd8)` | ModifyInk | inks 目标集 |
| `N(qub)`/`O(f2c)` | Remove/ReviveChars | locations cxc[] |
| `P(cm2)`/`Q(vd8)` | Create/ModifyGroup | members qo5[] |
| `S(je8)` | ModifyPositions | ie8[] |
| `T(r29)`/`U(vt9)` | NoteBundle/OpsBundle | ops uq9[] |
| `I/J/W/X(s83)` | DeleteEntities | 墓碑向量×4（th7） |
| `Y(ge8)` | ModifyPage | pages cxc[] |
| `b0(yn2)`/`c0(ke8)` | recordings | segmentation |
| `e0(le8)`/`u(td8)` | shapes/blocks | 目标集 |

## 统一模式（`lv2.N` 实证）

```java
int len = table.j();              // 向量长度
if (len <= 0) return hw3.I;       // 空 List 常量
th7 buf = m18.S();                // 可变 builder
for (i < len) { table.l(i, elem); // 逐位访问器
  buf.add(elem); }
return m18.E(buf);                // 不可变 List
```

- `m18.S/E` = Kotlin collections builder（`buildList`）。
- `hw3.I` = emptyList；`th7` = builder 实例；
  `di7 implements hmf` = IntRange 迭代器。
- 字节向量走 `ei7`/`nl8` 包装（路径编码元素）。

## 顶部静态

`lv2.a-h` = ±∞ 边界常量（oz/pz/qz/rz 1-4 维）；
`lv2.i` = `zp9(7)` 池。

## Harmony 核对

`decodeOriginal*Vector`/List 构建对齐：长度门 +
逐位访问 + 不可变 List 语义。

## 结论

物化层模式统一钉死——各表读侧共享同一套
lv2 向量→List 通道。
