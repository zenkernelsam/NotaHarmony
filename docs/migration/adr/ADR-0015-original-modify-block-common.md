# ADR-0015：原版 MODIFY_BLOCK common register 与可物化边界

- 状态：Accepted
- 日期：2026-08-10
- 关联：D-02、数据库 v36、ADR-0014

## 背景

Android 1.0.3 的 `haa.MODIFY_BLOCK=23`，payload table 为 `td8`。field 0 是
`qo5` Block identity vector；fields 1～9 与 17 分别为 corner、page、origin、
nullable rotation、nullable scale、size、textWrap、enableCaption、uint64 zIndex 和
positionLocked。`td8.a()`/`ddg.o()` 要求 page 与 origin 同时存在或同时缺席。

`qy0.c()` 证明 common block 不是整对象时钟：page+origin、rotation、scale、corner、
size、textWrap、enableCaption、positionLocked、zIndex 各自拥有独立 `fqb` LWW
register。`k2d/y2d` table 存在但 value 缺席表示 winning clear；CREATE_BLOCK 值只是
无 winner fallback，CREATE operation ID 不能伪装成初始 winner。

`bie/gp5` 在 common reducer 之后按 block type 分派专属字段：TEXT 的 paper 与
resizesWidthToFitText、IMAGE 的 crop/flip、MATH 的 latex/color。不同类型专属字段不能
混入 common reducer。

## 决策

1. 严格解码 `td8` 18 fields，拒绝空 target vector、重复 Block identity、page/origin
   半对、非法 SeqId、非有限 transform、负 size 和非法 uint64 z-index。
2. 数据库 v36 为九组 common register 保存 value、winner identity 和 winner-present；
   v35 DDL 单独冻结，保证 v34→v35→v36 不会因最终 DDL 提前带新列而重复 ALTER。
3. 本阶段从 DEFERRED 转为 APPLIED 的是 Harmony 已能完整物化的五组：page+origin、
   nullable rotation、nullable scale、size、zIndex。它们更新 TextBlock transform、
   bounds、block size、统一元素层序和 live/archive storage。
4. corner、`PIXEL_ALIGN/NO_WRAP`、enableCaption、positionLocked 虽已解码并有 v36
   预留列，但当前 TextBlock renderer、编辑 overlay 和 selection 尚未消费完整语义。
   携带这些字段的操作继续返回 `MODIFY_BLOCK_COMMON_BEHAVIOR_UNSUPPORTED`，不能仅写
   数据库后推进 cursor。fields 10～16 同样以 type-specific reason DEFERRED。
5. 每个 register 只接受严格更大的 unsigned `(timestamp,site)` operation identity；
   equal/stale 为 APPLIED no-op。从未修改的 register 没有 winner，因此较 CREATE ID
   更小的首个 MODIFY 仍可获胜。
6. 多 Block 先读取并校验全部 state、持久化 TextBlock、page assignment 与完整元素
   层序，再开始写入。跨 live/archive 页面搬运、register CAS、dense order、每页一次
   revision、文本搜索失效、inbox APPLIED 与 cursor 由外层同一 SQLite 事务提交；远端
   op 不写本地 operation log 或 Undo。

## 后果与验证

- `d02-modify-block-common.mjs` 覆盖真实 `td8` layout、五组物化 register、四组预留
  behavior gate、nullable clear、v34→v36、无 winner 的较小首次修改、stale no-op、
  跨页、uint64 层序、搜索失效、迁移/应用回滚和 type-specific gate。
- ArkTS fixture 覆盖 payload 23 dispatcher、两个 target、page/origin、value/clear
  wrapper、size、enum、boolean、uint64 上界与 field 17。
- 本阶段不关闭 corner/textWrap/caption/position lock 消费、TEXT paper/resize-to-fit、
  IMAGE/MATH、字符/样式操作、完整富文本或 D-02。
