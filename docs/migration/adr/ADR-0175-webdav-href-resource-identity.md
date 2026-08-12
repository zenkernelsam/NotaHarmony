# ADR-0175：WebDAV 对象身份来自 DAV href

## 决策

`WebDAVFileInfo.name` 固定为 `DAV:href` 解码后的末级资源名；`DAV:displayname` 单独保存为
`displayName`，只承担展示用途。完成批次 manifest 的枚举、规范文件名校验和 batchId 绑定
全部使用 href 派生的 `name`。

href 本身不再整串 `decodeURIComponent`。请求 URL 继续按原始 URI 的 `/` 分段并逐段规范化，
只在提取资源名时解码最后一个规范 path segment，避免 `%2F` 被提前变成层级分隔符。

每个 `DAV:response` 的规范 URL 还必须是本次 PROPFIND 集合自身或它的直接子项；集合自身
继续过滤，`../`、同源其他目录和违反 Depth:1 的深层资源使整个列表显式失败。

## 原因

WebDAV `displayname` 是可变属性，服务端可以省略、本地化或返回与 URI 末段不同的文字。
旧实现把它当作文件身份：合法 manifest 若有自定义 displayname 会无法恢复；反过来，普通
对象只要伪装 displayname 也会进入 manifest 候选下载。

Android 原版 1.0.3 没有 WebDAV 客户端可逐行移植；本项依据 RFC 4918 的 href/propstat/
Depth 语义和 Harmony XmlPullParser、HTTP 契约实现，不伪造原版 WebDAV 证据。

## 边界

不同真实 WebDAV 服务端对 displayname、保留字符编码和 Depth:1 响应集合的行为仍需设备
互操作矩阵验证。
