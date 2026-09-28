# Phase 966 — `pee` 合并写器 switch + setter 写器家族

来源：`decompiled_1.0.3/sources/defpackage/z0c.java`、`jgh.java`、
`ngh.java`、`k1j.java`、`wa0.java`

## 1. `pee` 结构

`pee` = z0c.invoke() 内匿名 `wx4` 合并类（R8 lambda-merge）：
约 30 注册项共享一个 `switch(discriminator)`，每项 `put`
绑定固定 case 序号 → 具体写器函数。

## 2. case→写器→类型 全表（cast 类型实证）

| case | 写器 | 类型 | 语义 |
|------|------|------|------|
| 0 | `vaj.k` | `pra` | Polygon def |
| 1 | `qcj.c` | `zgb` | ReceiveOpsEvent |
| 2 | `i1j.e` | `ra0` | AssetCloudPersisted |
| 3 | `tcj.c` | `akb` | RecordingAsset |
| 4 | `tej.g` | `pub` | RemoveChar |
| 5 | `vej.q` | `qub` | RemoveChars |
| 6 | `wfj.b` | `f2c` | ReviveChars |
| 7 | `iaj.c` | `yn2` | CreateRecording |
| 8 | `egh.b` | `lxc` | SeqMove |
| 9 | `jgh.c` | `z1d` | SetBool |
| 10 | `kgh.d` | `g2d` | SetColor |
| 11 | `ngh.d` | `k2d` | SetFloat |
| 12 | `mgh.c` | `j2d` | SetDecoratorStyle |
| 13 | （l2d SetMetadata 系） | | |
| 14 | `k1j.c` | `wa0` | AssetMetadata |
| 15 | `qgh.c` | `m2d` | SetPageBackground |
| 16 | `rgh.e` | `n2d` | SetPaper |
| 17 | `tgh.b` | `o2d` | SetParagraphAlignment |
| 18 | `laj.l` | `ao2` | CreateShape |
| 19 | `ugh.d` | `p2d` | SetRect |
| 20 | `zgh.c` | `y2d` | setter（double/long 系） |
| 21 | `dhh.c` | `z2d` | setter（int/long 系） |
| 22 | `ehh.g` | `a3d` | SetUInt8(cmf) |
| 23 | `qqi.d` | `sdf` | TransientInteraction |
| 24 | `oqi.c` | `tdf` | TransientInteractionEnded |
| 25 | `lti.d` | `mqf` | UpdateCheckbox |
| 26 | `q7j.c` | `io1` | ClearStyle |
| 27+ | `daj.b`/`i9j.f` | `tl2`/`yda` | CreateComment/PeerInteraction |

另：`wa0` AssetMetadata、`pra`/`akb`/`zgb`/`lxc`/`ra0`
等非-op 表亦走同一合并写器。

## 3. setter 写器解剖（`jgh.c`/`ngh.d` 实证）

```java
// z1d SetBool:
Boolean v = z1dVar.j();
aVar.C(1);
if (v != null) {
    aVar.l = true;                  // ★ 强制写默认值标志
    aVar.a(0, v.booleanValue(), false);
    aVar.l = false;
}
return aVar.n();

// k2d SetFloat: 同构，d(0, float, 0.0d)
```

- setter 表 = `C(1)` 单字段 + `l=true` 旁路默认值省略 —
  **`null` = "未设置"**（不写槽），非 null = 强制写出
  （即便等于默认值）。这正是读侧 setter-包装三态语义的
  写侧对应。
- `k1j.c` = `wa0` AssetMetadata 写器：4 字段
  `{assetHash:ua0@0, fileName@1, mimeType@2, fileSize:mmf@3}`，
  **required 三连 `z(4,6,8)`**。

## 4. `wa0` = AssetMetadata（新类型）

toString：`AssetMetadata(assetHash,fileName,mimeType,fileSize)`；
`ua0` = 16B asset-hash 内联结构（yec case `aa6.x0`）；
`mmf` = int 值类包装。

## 5. Harmony 对齐

Harmony 写侧 setter = `encodeOptional{Bool,Float,...}` 三态
（写于原稿 replay）。`l=true` force-write 语义 = Harmony
字段存在性编码（有值必写）——语义等价。

## 6. 验证

`d02-pee-writer-switch.mjs` 静态断言。
