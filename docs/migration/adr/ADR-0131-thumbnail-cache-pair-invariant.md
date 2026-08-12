# ADR-0131：缩略图 revision 与 PixelMap 必须成对发布

日期：2026-08-12

## 决策

库页只有在相同 noteId 同时存在匹配 revision 和 PixelMap 时才复用缓存。渲染没有产生 PixelMap 时不写 revision；下一轮仍会重试，而不是把“空结果”永久缓存成成功。

## 原因

revision 是 PixelMap 内容身份，不是独立完成标记。二者分离会导致 `oldRevision === revision` 分支跳过渲染，使卡片在同一内容版本内永久显示占位图。
