# ADR-0388：照片插入来源页上下文绑定

- 状态：已接受（2026-08-25）
- 场景：照片选择与剪贴板图片导入都是长异步入口。旧实现先捕获页代与页 ID，但 `insertOriginalPhotos` 在 await 后重新读取 loaded page、纸张、缩放和画布中心；用户切换页面或视口后，图片可能提交到新页，锚点也会漂移。
- 决策：在异步进入前构造不可变 `OriginalPhotoInsertOrigin`，统一固化 generation、pageId、pageWidth、pageHeight、zoom 和 center。选择器返回后先要求来源页仍当前；持久化成功但页面已过期时保留 durable 数据，不推送历史、不改 UI。剪贴板锚点同样在权限与导入前解析。
- 结果：跨页迟到提交被阻止，插入几何使用发起时语义；失败提示仍只出现在来源上下文，photoImportBusy 继续由 finally 清理。
