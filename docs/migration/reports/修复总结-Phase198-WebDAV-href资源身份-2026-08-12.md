# Phase 198 修复总结：WebDAV href 资源身份

## 发现

PROPFIND 解析把 `DAV:displayname` 写进 `WebDAVFileInfo.name`，而恢复入口又用该字段筛选并
绑定 `batch-<batchId>.manifest.json`。展示属性与真实 href 不一致时，合法完成批次会漏掉；
错误对象也可能凭伪造 displayname 进入候选。

同时，旧解析先对完整 href 执行 `decodeURIComponent`，会把文件名 segment 内的 `%2F`
提前变成目录 `/`，改变远端资源层级和后续下载 URL。

解析器虽然拒绝跨 origin href，却仍接受同源其他目录、`../` 和 Depth:1 下的深层响应；
这些对象可能凭规范 manifest 文件名进入恢复候选。

## 修改

- `name` 改为始终由解码后的 `DAV:href` 末段产生
- 新增 `displayName` 保存服务器展示属性并在缺失时回退资源名
- href 请求 URL 保持按原始路径 segment 规范化，只解码最终资源名 segment
- 保留 `%2F` 等编码分隔符在原 path segment 内，不再改变层级
- 只接受请求集合自身或直接子项，拒绝 dot segment、同源越界与深层伪响应
- manifest 枚举与规范文件名绑定继续只读取 `name`
- 更新 ArkTS WebDAV parser 测试
- 新增 href 身份 replay，并补强既有 batch identity replay

## 验证

- 专项 replay：`TOTAL=10 FAILED=0`
- batch manifest 身份 replay：`TOTAL=4 FAILED=0`
- WebDAV/批次相关 replay：10 个文件、`TOTAL=52 FAILED=0`
- 系统 Backup 回归：9 个文件、`TOTAL=54 FAILED=0`
- `git diff --check`：通过
- HAP 未执行：仓库根目录没有 `hvigorw`/`hvigorw.bat`
- 未启动设备、模拟器、虚拟机或 Hypium

## 未闭环

真实服务端的 displayname 省略、本地化和自定义值仍需互操作测试；恢复跨篇事务保持既有
边界。
