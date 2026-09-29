# ADR-1018：变换项 ie8 + 快照-构建器环

## 状态

已接受（Phase 1074）。

## 决策

- `ie8` = `{origin:fqa, page:cxc, rotation:k2d(Float),
  scale:y2d(qed), id:qo5, zIndex:tmf}` 六元组；校验 `ddg.e`。
- `yy3`/`xy3` = 快照↔构建器环（`build()`/`builder()`）。

## 依据

`ie8` FlatBuffers 六访问器 + `yy3.builder()→xy3`/`xy3.build()→yy3`。

## 后果

Harmony 变换项按六元组；实体快照不可变、经 builder 复原。
