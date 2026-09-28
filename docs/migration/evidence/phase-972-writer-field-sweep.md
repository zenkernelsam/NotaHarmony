# Phase 972 — 全部表写器字段数/required 槽总稽查

来源：`decompiled_1.0.3/sources/defpackage/*.java`

对 41 个注册表写器逐一抽 `aVar.C(N)` + `z(iN,slot)`，
得完整写侧字段宽表（req = vtable 槽位 = 4+2·fieldIdx）。

## 1. op 表写器

| type | 写器 | C(N) | required 槽 | 对应字段 |
|------|------|------|-------------|----------|
| e46 | fci.d | 3 | — | InsertChar（写侧全可选！） |
| f46 | kci.j | 3 | 6 | f1 string |
| pub | tej.g | 2 | 4 | f0 location |
| qub | vej.q | 2 | 4 | f0 locations |
| f2c | wfj.b | 2 | 4 | f0 locations |
| yn2 | iaj.c | 6 | 4 | f0 recording |
| ke8 | z0j.l | 4 | 4 | f0 recording |
| ln2 | haj.c | 4 | — | CreatePage（无 required） |
| ge8 | r0j.d | 4 | 4 | f0 pages |
| dm2 | ys2.O | 20 | 4,6,18 | f0+f1+f7（19 参平铺签名） |
| wd8 | o0j.f | 19 | 4 | f0 inks |
| ao2 | laj.l | 18 | 4,6,14,22 | f0 shape+f1 kind+f5 defKind+f9 color |
| le8 | a1j.c | 17 | 4 | f0 shape 必需 |
| cm2 | eaj.b | 1 | 4 | f0 members |
| vd8 | l0j.c | 2 | 4,6 | f0 group+f1 members |
| rl2 | baj.c | 21 | 8,10,16 | f2 page+f3 origin+f6 size |
| td8 | j0j.e | 18 | 4 | f0 blocks 必需 |
| je8 | x0j.m | 1 | 4 | f0 positions |
| he8 | v0j.d | 10 | — | ModifyParagraphStyle |
| me8 | c1j.c | 15 | 4,6 | f0 start+f1 end |
| io1 | q7j.c | 4 | 4,6 | f0 start+f1 end |
| ee8 | p0j.d | 5 | 4,6 | f0 field+f1 value |
| mqf | lti.d | 3 | — | UpdateCheckbox |
| yda | i9j.f | 7 | — | PeerInteraction |
| tl2 | daj.b | 3 | 6,8 | f1 anchor+f2? |
| ud8 | k0j.c | 4 | 4 | f0 comment |
| tdf | oqi.c | 2 | 4 | f0 interactionId |
| sdf | qqi.d | 2 | — | TransientInteraction |
| ra0 | i1j.e | 1 | 4 | f0 asset |

## 2. 非 op 表写器

| type | 写器 | C(N) | required |
|------|------|------|----------|
| q89 | q5j.b | 2 | 4,6 |
| nz9 | vv7.L | 5 | — |
| k3a | fag.n0 | 6 | — |
| sw9 | j7j.c | 6 | — |
| p9 | kvi.f | 1 | 4 |
| zgb | qcj.c | 3 | 4,6 |
| akb | tcj.c | 1 | 4 |
| dp5 | iuh.c | 2 | 4,6 |
| wa0 | k1j.c | 4 | 4,6,8 |
| lhe | qdi.a | 2 | 6 |
| my3 | rr2.b | 1 | — |

## 3. 关键发现

- **e46/ln2/le8/td8/mqf/yda/sdf/nz9/k3a/sw9/my3 写侧
  无 required**——required 是读侧校验概念，写侧仅对
  核心键（id/锚点/成员）置 z()。
- `v0j.d` 内嵌 **b3d 写器现场实证**：写 he8 时先建
  `C(1)`+`c(0,bcg.I,0)` 内嵌表再 h() 引用——Phase 949
  "b3d 缺席注册表"机理完全坐实。
- `ys2.O` = 19 参平铺签名工厂（非 dm2 对象），C(19)。
- `f46` 唯一 f1 string required；`wa0` 三连 required。

## 4. 验证

`d02-writer-field-sweep.mjs` 重算 C(N)/required 逐一对账。
