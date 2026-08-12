# ADR-0163：删除笔记的存在性与资产回滚门

## 决策

`NoteRepositoryImpl.deleteNote()` 在事务内先确认 note 存在，并要求最终删除恰好影响一行；
否则抛错并回滚本次资产引用变更。

## 原因

并发删除或重复 UI 请求可能让 `DELETE note_meta` 影响 0 行。旧实现仍提交事务，导致共享
`note_asset.note_ids` 已移除该 note，即使笔记删除实际失败。

## 验收

不存在 note、并发消失和正常删除分别覆盖：失败不改资产，正常删除只影响一行并清理引用。
