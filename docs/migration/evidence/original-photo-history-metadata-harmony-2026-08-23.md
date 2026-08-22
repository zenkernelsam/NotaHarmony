# 多图照片历史元数据审计证据（2026-08-23）

## 审计范围

- NoteCanvasView.commitOriginalPhotoInsert()；
- StrokePersistence.commitOriginalImageInsert() / ppendHistoryCompanion()；
- PersistentHistory.groupEvents() / educePersistentHistoryTail() / materializeAction()；
- PageMutationOpCodec.classifyPageMutation()。

## 确认有效的部分

1. 每张照片的 ORIGINAL_CREATE_BLOCK 和 history companion 在同一个 editor transaction 内提交；
2. 多张照片重复使用 prepared metadata 的 ctionId/effect/coalesceTrack/actionTime；
3. groupEvents() 只合并相邻且四元组完全一致的 PUSH metadata；
4. materializeAction() 要求元素操作同 note/page、op type 与 payload 一致，且 romRevision/toRevision 连续；
5. 运行时使用一个最终 ADD_ELEMENTS action，与持久 reducer 的单个 grouped action 对应。

## 发现的缺陷

多图最终 action 的 ddedElementOrder=[]。sameAddedElementRefs() 要求该数组长度等于所有 added 元素数量，
因此 N>0 时 alidateActionState() 返回 false，pplyAction() 不执行，commitUndo()/commitRedo() 不被调用。
单图路径不受影响，因为它走 ADD_ELEMENT；clipboard Paste 已提供 refs。

## 修复证据

- 最终 action 从最后一张返回的完整页序取 inalOrder；
- 新增 ddedElementOrder 按 inalImages 顺序生成 IMAGE ref；
- zIndex 从捕获的 lementOrderBefore.length 连续递增；
- 新增 OriginalPhotoHistoryMetadata.test.ets 并注册到 List.test.ets；
- 新增 d02-original-photo-history-metadata.mjs，当前 7/7 通过。