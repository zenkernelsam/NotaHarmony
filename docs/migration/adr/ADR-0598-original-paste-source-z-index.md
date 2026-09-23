# ADR-0598: 剪贴板粘贴保留源 zIndex（仅 Ink，o8j/u6a 对齐）

- 状态：accepted（2026-09-28，Phase 629）
- 证据：`docs/migration/evidence/original-paste-source-z-index-2026-09-28.md`

## 背景

原版剪贴板记录的 zIndex 携带是不对称的：仅 Ink 记录 `u6a`
有 `long j` 序列化 z 字段，粘贴生产者 `o8j.a` 以
`new xgb(u6aVar2.j)` 逐字回填 CreateInk zIndex 槽；Shape 记录
`ge3` 与 Block 记录 `ry0` 无 z 字段，其粘贴生产者
（`u5j.j`/`baj.a`）的 xgb 槽恒为 `null` → clientTime 顶层序。

Harmony 侧 `commitOriginalClipboardPaste` 此前对所有种类一律
省略 zIndex → 全部 clientTime。Ink 分叉最可观察：复制 999999
衬底荧光笔再粘贴，Harmony 把它弹到顶层，原版保持衬底。

## 决定

1. 粘贴循环内对 `ref.kind === STROKE` 调用
   `readOriginalClipboardSourceZIndex`：按源 elementId（op-id，
   全局唯一）直查 `original_element_z_index`，**不限**
   note/page/visible —— cut 源（visible=0）与跨页/跨笔记
   粘贴均命中；无行/多行 → `undefined` fail-closed 回退。
2. `encodeOriginalLocalCreateInk(page, stroke, sourceZIndex)`
   接线既有 zIndex 形参；Shape/Text/Image/Math 不传 z ——
   复刻原版 `xgb=null → clientTime` 同约。
3. z-clock 护栏收窄为逐元素：仅 `sourceZIndex === undefined`
   （回退 clientTime）时校验 `clientTime > maximumZIndex`；
   显式源 z 按原版逐字插入。
4. 编码器层补齐 CreateShape(field 12→offset 28) 与
   CreateBlock(field 9→objectSize +8) 的 `zIndex?: string`
   形参 —— 线格式槽位本就存在且解码端已读，补齐仅为格式
   完整性；当前无调用方接线，字节零变化。

## 边界（有意不移植）

- 原版复制时固化 z；Harmony 粘贴应用时读当前行 —— 复制后
  源 z 被改的窄边界下取当前 z，方向 fail-closed。
- Group z：原版 group create 无 z 槽，两端同约。

## 验证

- `d04-original-paste-source-z-index.mjs` 38/38；全量 Replay、
  双 HAP clean 构建见 Phase 629 报告。
