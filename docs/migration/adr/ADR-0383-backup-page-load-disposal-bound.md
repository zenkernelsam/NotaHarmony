# ADR-0383：备份页加载销毁绑定

- 状态：已接受（2026-08-25）
- 场景：`BackupPage.reloadPage()` 在数据库初始化与配置读取 await 后发布配置和就绪态；原检查缺少生命周期代际捕获，销毁后的旧续体仍可覆盖 UI。异常与 finally 只按加载代判断，可能把已换代任务标记为 initialized，也可能在已换代时错误回写错误状态。
- 决策：进入加载前捕获 `expectedLifecycleGeneration`；销毁时递增该代际。成功、失败与 finally 统一通过 `isStaleReload()` 联合校验销毁、生命周期代和加载代。
- 结果：无效续体不再发布 READY/ERROR，也不再污染 `initialized`；备份页导出、导入、云端备份与恢复的既有操作门禁保持不变。
