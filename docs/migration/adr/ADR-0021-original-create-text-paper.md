# ADR-0021：原版 CREATE_BLOCK TEXT paper 与 resize baseline

## 状态

已接受，D-02 Phase 42 第一子批。

## 原版证据

- `rl2.java` 的 21-field CreateBlock accessor 明确映射：field 15 为 `k3a paper`，field 18 为 `resizesWidthToFitText`，field 19 为 margins，field 20 为 positionLocked。
- `k3a.java` 保存 flair、spacing、bleeds、centered、RGBA 和 legacyPaperIndex，并拒绝非不透明背景色。
- `rl2.a()` 只允许 TEXT 携带 paper；IMAGE/MATH 携带 paper 是非法组合。

## 决策

1. `TextBlockElement` 增加可选 `paper` 与 `resizesWidthToFitText`，旧 Harmony 快照缺席时仍兼容。
2. CREATE_BLOCK 解码 field 15 的完整 `k3a`，并把 paper JSON 保存为 `original_block_state.create_text_paper` baseline；数据库升至 v40，v39→v40 使用单列 ALTER migration。
3. field 18 不再被 CREATE 路径拒绝。renderer 在 resize-to-fit 时不按旧 blockWidth 强制换行；持久化的 blockWidth 不在渲染阶段被隐式改写。
4. TEXT paper renderer 消费原始 RGBA、flair、spacing 与 centered，支持 lines/grid/dots，并裁剪到 block bounds。
5. MODIFY_BLOCK field 13 paper setter、field 16 resize 独立 winner 尚未实现，仍保留 type-specific DEFERRED 门。

## 验证

- `d02-create-block.mjs` 使用真实 21-field `rl2` 形状和嵌套 `k3a`，覆盖 paper 六字段、resize、默认 margins、v39→v40、live/archive、回滚和 IMAGE/MATH DEFERRED。
- 全部 D-02 Node/SQLite replay 通过。
- clean 后 `note@ohosTest` 与 `note@default` assembleHap 均 `BUILD SUCCESSFUL`。

## 限制

设备像素效果、ROUND corner 裁剪、编辑覆盖层精确测量宽度以及 MODIFY paper/resize LWW 仍待后续批次与真机验收。
