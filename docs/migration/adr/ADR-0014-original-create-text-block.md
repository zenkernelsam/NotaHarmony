# ADR-0014：原版 CREATE_BLOCK 文本容器基线

- 状态：Accepted
- 日期：2026-08-10
- 关联：D-02、数据库 v35、ADR-0003、ADR-0004、ADR-0013

## 背景

Android 1.0.3 的 `haa.CREATE_BLOCK=22`，payload table 为 `rl2`。`rl2` 有 21 个
字段，覆盖 block type、page/origin、rotation、scale、size、corner、text wrap、
caption、z-index、Image/Math/Paper 专属数据、图片翻转、文本宽度自适应、margins 和
position lock。`rl2.a()` 明确校验 TEXT/IMAGE/MATH 的专属字段边界；未知 enum 由生成
accessor 回落到首项。

`ry0` 的 common block model 把 CREATE 值作为 page+origin、rotation、scale、size、
corner、textWrap、enableCaption、positionLocked 与 zIndex register 的无 winner 基线。
TEXT block 创建时只是一个空 RichText 容器；实际字符和样式由 payload 7～14 的
INSERT/REMOVE/REVIVE/STYLE 操作写入，不能从 CREATE_BLOCK 猜出正文。`whe.b =
fsi.f(3,10,5,5)` 证明 margins 字段缺席时依次采用 top=3、bottom=10、left=5、right=5。

## 决策

1. 严格解码 `rl2` 21 fields，required page/origin/size 缺失、非法 SeqId、非有限几何、
   负尺寸或 margin、非法 uint64 z-index 均不写页面。
2. 当前只把可无损表达的 TEXT 子集从 DEFERRED 转为 APPLIED。IMAGE、MATH、paper、
   caption、resize-to-fit、position lock 以及误配的 Image/Math 字段继续返回具体
   DEFERRED reason，不能降级成普通文本。
3. TEXT element ID 使用 CREATE_BLOCK operation ID；创建 `richText=''`，本地 block
   位于 `(0,0)`，由 origin、rotation、scale 组成 `translate * rotate * scale`；size
   与 left/top inset 写入现有 `TextBlockElement`。
4. `TextBlockElement` 目前要求标量 `fontSize/fontColor`。空字符串使用 `fontSize: 17`
   与 signed black `fontColor: -16777216` 只是持久化模型必填占位；它们不代表原版默认
   富文本样式，也不能覆盖后续字符/样式 reducer 重建出的权威 RichText 状态。
5. 数据库 v35 新增 `original_block_state`，保存 CREATE common baseline、四边 margins
   和完整 uint64 z-index。该状态以 block identity 外键关联统一元素层序，供后续
   MODIFY_BLOCK 独立 LWW register 恢复 CREATE fallback。
6. live page 与远端删除归档使用同一层序检查和物化规则。block state、element、
   dense order、content revision、搜索失效、inbox APPLIED 与 cursor 仍由外层单一
   SQLite 事务提交；远端 CREATE_BLOCK 不写本地 operation log 或 Undo。

## 后果与验证

- `d02-create-block.mjs` 覆盖真实 `rl2` 布局、缺席 margins 默认值、空文本、transform、
  uint64 z-index、v34→v35、live/archive 层序、搜索失效、迁移/应用回滚和
  IMAGE/MATH deferred gate。
- ArkTS fixture 覆盖 payload 22 dispatcher、required inline fields、transform、size、
  margins 和 uint64 上界；数据库契约测试覆盖 migration 与外键。
- 本阶段不关闭 MODIFY_BLOCK、payload 7～14 字符/样式操作、完整富文本、IMAGE/MATH
  block、Pencil/Tape/effects、NOTE_BUNDLE 内容 replay、认证 transport 或 D-02。

## 2026-08-12 本地创建出站补充

ADR-0100 在不改变上述入站基线的前提下增加严格本地 Text 子集：type-22 只创建空容器，
初始非空正文由独立 type-8 写入；两条生产 reducer 共享一个 revision batch，使同一用户命令
保持 `N→N+1`。IMAGE/MATH CREATE_BLOCK 与既有 Text 的完整编辑出站仍未因此关闭。
