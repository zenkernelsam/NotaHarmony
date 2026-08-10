# ADR-0020：原版 MODIFY_BLOCK 的 TEXT common 字段消费

## 状态

已接受，D-02 Phase 41 第一子批（代码与桌面 replay 已验证）。

## 原版证据

- `decompiled_1.0.3/sources/defpackage/td8.java`：`corner` 使用 `ty0`（`SQUARE=0`、`ROUND=1`），`textWrap` 使用 `ive`（`PIXEL_ALIGN=0`、`NO_WRAP=1`），`enableCaption` 为独立 Boolean 字段。
- `decompiled_1.0.3/sources/defpackage/qy0.java:c(...)`：MODIFY_BLOCK 将三者分别送入 `BlockCommonImpl` 的独立 register；它们不是 type-specific 字段，也不应在 decoder 后统一 DEFERRED。

## 决策

Harmony 的 `TextBlockElement` 现在保留 `corner`、`textWrap`、`enableCaption`，并由 CREATE_BLOCK baseline 与 MODIFY_BLOCK winner 共同物化。`textWrap=PIXEL_ALIGN` 按 block 可用宽度换行，`NO_WRAP` 只按显式换行分行；旧快照缺席时按原版默认 `SQUARE/PIXEL_ALIGN/false` 解释。所有 winner 更新仍与元素快照、层序、页面 revision 和搜索失效处于同一 inbox 事务。

`enableCaption` 对当前 TEXT-only renderer 没有额外视觉内容，因此只保留语义状态；IMAGE/MATH caption、TEXT paper、resize-to-fit 以及其余 type-specific fields 继续 DEFERRED，不能以字段落库冒充完整支持。

## 验证

- `node docs/migration/replays/d02-modify-block-common.mjs`：通过，覆盖 common register 消费、LWW、跨页、回滚和 type-specific DEFERRED 门。
- `node docs/migration/replays/d02-richtext-style.mjs`：通过。
- clean 后 `note@ohosTest` 与 `note@default` `assembleHap`：均 `BUILD SUCCESSFUL`。

## 限制与后续

当前没有设备运行态验证；换行的复杂字形 shaping、RTL、输入法编辑覆盖层和圆角视觉背景仍待后续 TEXT/RichText 批次与真机验收。
