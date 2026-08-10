# ADR-0017：原版 RichText 字符插入序列

- 状态：Accepted
- 日期：2026-08-10
- 关联：D-02、数据库 v37、ADR-0014、ADR-0016

## 原版证据

Android 1.0.3 的 `haa` 将 payload 7/8 定义为 `INSERT_CHAR`/`INSERT_STRING`；
`zq9` 分别把它们映射为 `e46`/`f46`。两种 payload 的 field 0 都是 nullable
`cxc` location，field 2 都是 nullable `qo5` textField；中间字段分别是 uint32
Unicode code point 和 required UTF-8 string。

`e4c` 按 Unicode code point 而非 UTF-16 code unit 展开字符串，并用 operation
identity 加字符串内 index 形成字符 SeqId。Java UTF-8 解码对畸形输入产生 replacement
character，不能把网络同步中的历史坏字节升级为整批严格拒绝。`iwc` 将 INSERT_STRING
保存为连续 SeqId range：首字符挂在 location，后续字符可以通过同一 op identity 的
index 寻址。`ixc.a` 根锚点是 `site=0xFFFF,timestamp=0,index=0`。

## 决策

1. 数据库 v37 新增 `original_text_character`。每个字符保存 Block identity、字符
   `(timestamp,site,index)`、nullable parent SeqId、Unicode code point 和 visible
   tombstone 位；Block 删除通过外键级联清理字符状态。
2. 根 location 规范化为 null。首字符 parent 为 payload location，INSERT_STRING
   后续字符 parent 为前一字符；同一 parent 的 sibling 使用原版 SeqId 比较器降序，
   保持乱序和并发重放的确定结果。
3. 非根 location 先从字符表反查所属 Block。payload 同时携带 textField 时二者必须
   一致；根插入没有 textField、缺锚点或跨 Block 锚点均保持 DEFERRED，不能猜唯一文本块。
4. 旧 Harmony 非空纯文本 snapshot 没有字符身份，不能安全生成历史 SeqId，因此保持
   `INSERT_TEXT_STATE_DIVERGED`。空 CREATE_BLOCK 可以从首个插入建立字符状态；之后每次
   应用前，字符树物化值必须与 snapshot 完全一致。
5. 字符行、live/archive snapshot、元素 revision、页面 content revision、搜索失效、
   inbox 状态和 cursor 由 inbox 外层单一 SQLite 事务提交。远端插入不写本地 operation
   log，也不在本阶段猜测自动尺寸；原版自动尺寸由后续 MODIFY_BLOCK/RichText layout 流完成。
6. `visible` 为后续 REMOVE/REVIVE 保留。本阶段只写 visible=1，不声明删除、样式、段落
   样式、换行测量或完整 RichText 已完成。

## 验证边界

- `d02-insert-text.mjs` 使用真实 `e46/f46` FlatBuffer 布局，覆盖 ASCII、中文、补充平面
  code point、畸形 UTF-8 replacement、根/锚点插入、并发 sibling、缺锚点、跨 Block、
  无绑定目标、snapshot 分歧、live/archive、搜索失效、v36→v37、双回滚与级联删除。
- `SyncedOperationInbox.test.ets` 注册真实 payload 7/8 fixture，并验证总分发器支持两类操作。
- 本 ADR 不关闭 REMOVE/REVIVE、style/paragraph-style、RichText 字形布局、Block 自动尺寸、
  IMAGE caption、NOTE_BUNDLE 内容 replay、认证 transport 或完整 D-02。
