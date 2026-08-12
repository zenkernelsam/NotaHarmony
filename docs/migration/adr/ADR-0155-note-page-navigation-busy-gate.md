# ADR-0155: NotePage 翻页入口 busy 门禁

## 决策

`NotePage` 的前后翻页回调在修改 `currentPageIndex` 前，必须同时确认页面未处于初始加载和页级写操作状态。页增删、重排、设置继续使用已有 `runPageOperation()` 门禁。

## 原因

页索引变化会触发画布保存旧页并异步加载新页。若在 `pageLoading` 或另一页操作期间重复点击，多个切页请求会争用父组件状态，增加迟到结果和 UI 选择状态错乱风险。门禁只抑制无效入口，不改变正常单次翻页。

## 验收

静态 replay 检查 prev/next 两个回调均包含 `!pageLoading && !pageOperationBusy`，并保留原有边界判断。
