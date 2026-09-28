# Phase 964 — `zq9` 写侧全貌：类→haa 逆映射 + Op 信封写器

来源：`decompiled_1.0.3/sources/defpackage/zq9.java`

## 1. `zq9.a` = 静态 `mx7` Map<KClass,haa>（30 项）

```
l2d→SET_METADATA        ra0→ASSET_CLOUD_PERSISTED
ln2→CREATE_PAGE         ge8→MODIFY_PAGE
yn2→CREATE_RECORDING    ke8→MODIFY_RECORDING
e46→INSERT_CHAR         f46→INSERT_STRING
pub→REMOVE_CHAR         qub→REMOVE_CHARS
f2c→REVIVE_CHARS        me8→MODIFY_STYLE
he8→MODIFY_PARAGRAPH_STYLE  io1→CLEAR_STYLE
dm2→CREATE_INK          gd→ADD_PATH_ELEMENTS
wd8→MODIFY_INK          ao2→CREATE_SHAPE
le8→MODIFY_SHAPE        cm2→CREATE_GROUP
vd8→MODIFY_GROUP        rl2→CREATE_BLOCK
td8→MODIFY_BLOCK        je8→MODIFY_POSITIONS
s83→DELETE_ENTITIES     tdf→TRANSIENT_INTERACTION_ENDED
ee8→MODIFY_PDF_FIELD    mqf→UPDATE_CHECKBOX
yda→PEER_INTERACTION    tl2→CREATE_COMMENT
ud8→MODIFY_COMMENT
```

**订正 Phase 919**：`ee8` = **MODIFY_PDF_FIELD**（非 UpdateComment）。
30 项（NONE 无类）。

## 2. `b(cee)` — 逆查 + fail-loud

```java
haa = a.get(npb.b(cee.getClass()));
null → rgc.b(KClass名) throw   // "Unknown type...data loss"
```

## 3. `e(...)` — **Op 信封 7 字段写器**

```java
int iA = ree.a(payload, builder);        // 先递归序列化 payload
int? sdfOff = sdf != null ? qqi.d(sdf,a) : null;
aVar.C(7);
j(0, rh8.O(id));                          // f0 id (required)
f(1, clientTime);                         // f1 long
if (srv!=null) f(2, tmf.I);               // f2 serverTime ULong
if (aud!=null) f(3, tmf2.I);              // f3 audioTime ULong
c(4, b(cee).I, 0);                        // f4 payloadType byte(默认0)
h(5, iA);                                 // f5 payload (required)
if (sdfOff!=null) h(6, sdfOff);           // f6 transientInteraction
z(iN, 4);  z(iN, 14);                     // required: f0(slot4)+f5(slot14)
```

**与 Phase 905 读侧镜像**：读 c(4)id/c(6)clientTime/c(8)serverTime/
c(10)audioTime/c(12)payloadType/c(14)payload/c(16)transient
⇔ 写 f0-f6 + 两 required（id + payload）。

## 4. `zq9` 其余成员

- `c(uq9)` = `z5c.x` 别名（payload 读分派）
- `d(uq9,a)` = 入口（抽 6 访问器 → e）
- `a(qo5,cee,long,xgb)` = **op 工厂**（组装 uq9 实例）

## 5. Harmony 对齐

信封写侧字段序 + required 约束 + payloadType 逆映射 +
fail-loud——Harmony `encodeOriginalOperation` 应镜像；
ee8 命名订正进总纲。

## 6. 验证

- `d02-zq9-envelope-writer.mjs` 静态断言。
