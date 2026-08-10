# ADR-0018：原版 RichText 字符可见性寄存器

- 状态：Accepted
- 日期：2026-08-10
- 关联：D-02、数据库 v38、ADR-0017

## 原版证据

Android 1.0.3 的 `haa` 将 payload 9/10/11 定义为 `REMOVE_CHAR`、
`REMOVE_CHARS` 和 `REVIVE_CHARS`；`zq9` 分别把它们映射为
`pub`、`qub` 和 `f2c`。`pub` field 0 是 required inline `cxc`
location，`qub/f2c` field 0 是 required non-empty inline SeqId vector；三者
field 1 都是 nullable `qo5` textField。

`iwc` 不允许删除 RichText root。删除未知位置会 deferred；删除一个父字符只改变
该字符的 tombstone，后代仍保留在 SeqId 树中并继续按原顺序物化。REMOVE 写入
tombstone，REVIVE 清除 tombstone。`njj.L` 中 map value `TRUE` 表示 deleted。

`al2` 为每个字符保存带 operation identity 的可见性 LWW，而不是普通 boolean。
incoming identity 在 `so5.a(old,new) <= 0` 时覆盖；`so5` 先按 unsigned timestamp，
再按 unsigned site 比较，因此相同 identity 允许幂等重放，较旧操作不得改变当前 winner。

## 决策

1. 数据库 v38 为每个 `original_text_character` 增加 nullable winner timestamp/site 和
   显式 present 位。v37 迁移继续使用冻结 DDL，v38 只添加新列，旧字符以 winner absent
   开始，第一次合法 visibility op 可以按原版 LWW 获胜。
2. REMOVE_CHAR 解码单个 required inline SeqId；REMOVE_CHARS/REVIVE_CHARS 解码 required
   non-empty SeqId vector。批量目标先去重，root、缺字符、跨 Block 或 textField 分歧会在
   任何 UPDATE 前使整条 op 保持 DEFERRED。
3. visibility winner 按每个字符独立比较。较新或相同 identity 同时更新 tombstone 与
   winner；较旧 identity 是成功 no-op。删除父字符不删除或重挂后代，物化只跳过不可见
   字符本身。
4. winner 推进但物化文本不变时，不写 snapshot、不增加元素或页面 revision，也不清除
   搜索索引。只有物化文本实际改变时才更新 live/archive snapshot、revision 和搜索状态。
5. 字符 winner、snapshot、revision、搜索失效、inbox APPLIED 和 server cursor 继续由 inbox
   外层单一 SQLite 事务提交。远端 visibility op 不写回本地 operation log。

## 验证边界

- `d02-text-visibility.mjs` 使用真实 `pub/qub/f2c` FlatBuffer 布局，覆盖 v37→v38、
  父字符删除但后代保留、batch remove/revive、逐字符严格 LWW、stale revive、同值 winner
  不增 revision、missing/root 原子拒绝、live/archive、搜索失效、双回滚和级联删除。
- `SyncedOperationInbox.test.ets` 注册真实 payload 9/10/11 fixture，并验证总分发器支持三类操作。
- 本 ADR 不关闭 character style、paragraph style、RichText 字形/layout、Block 自动尺寸、
  IMAGE caption、NOTE_BUNDLE 内容 replay、认证 transport 或完整 D-02。
