# Phase 1055 证据 — 线级信封三层（Op/OpsBundle/NoteBundle）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `uq9` Op 信封（toString 实名）

`Op(id:qo5, clientTime:long(njj.j0(10,·) 格式),
serverTime:tmf, audioTime:tmf, payload:cee→z5c.x 分派,
transientInteraction:sdf)`

- `p(qo5)`/`r(sdf)`/`q(cee)` = 依赖/瞬态引用访问器。

## `vt9` OpsBundle

`{ops:uq9[](l(idx)+j() 数), schemaVersion:short(ymf.a 格式)}`
——`lv2.U` 物化 ops 列表。

## `r29` NoteBundle（文件级表，StringBuilder 实名）

`{noteId:utf, legacyNoteId:utf, editorSite:short,
editorUserId:String, createdAt:long, creatorUserId:String,
ops:uq9[](r()+lv2.T), schemaVersion:short(q())}`

- **noteId + legacyNoteId 双 ID**：旧版 ID 迁移桥。
- editorSite = 站点短码（CRDT 站点），editorUserId/
  creatorUserId 分离。
- `lv2.T(r29)` = 文档 ops 物化器（m09.a 调用，Ph1037）。

## `sdf` TransientInteraction

`{interactionId:qo5 required, timeout:mmf}`——
校验：interactionId 必填（"Interaction Id is currently
required"）；timeout 已弃（"Timeout is currently unused,
including this has no effect"——携带即拒绝？实测文案）。

## 三层嵌套

`NoteBundle(r29) ⊃ ops:uq9[] ⊃ payload(z5c.x→31 载荷)`；
`OpsBundle(vt9)` = 同步线格式（ops+schemaVersion）。

## Harmony 决策

三层信封字段+双 noteId 迁移桥+瞬态引用保留。

## 产出

- fixture `d02-wire-envelopes.mjs`（12 断言）。
- ADR-0999；中文报告。
