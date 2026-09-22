# ADR-0527: 原版超限图片提示

日期：2026-09-22（Phase 556）

## 背景

原版图片插入超限（rd9 事件 → u49 snackbar）有专属文案
"Image is too large to add."；Harmony 已有 100MB 字节闸口但所有失败都弹
通用 `original_photo_insert_failed`。

## 决策

1. `OriginalPhotoIngress` 新增 `OriginalPhotoTooLargeError` 替换两处超限
   `Error`（stat 预检 + 读取后校验）。
2. `NoteCanvasView.photoErrorToastRes(e)` 按 `instanceof` 映射专属文案，
   三个图片入口（相册/剪贴板/拍照）共用，busy/lease 语义不变。

## 差异登记

原版超限判定基于解码像素维度，Harmony 基于字节上限（100MB）——判定面
不同但用户语义一致（图片过大→专属提示）。

## 备选

- 按错误消息文本匹配：消息属实现细节，不可靠，弃用。
- 解码后再判像素：引入额外解码成本；字节闸口已覆盖极端超限，像素级判定
  登记为后续工作。
