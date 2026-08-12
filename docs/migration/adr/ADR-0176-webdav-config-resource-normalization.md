# ADR-0176：WebDAV 配置绑定单一资源规范

## 决策

WebDAV 的设置页测试、保存事务、旧配置迁移、持久化读取和客户端构造全部调用同一个
`normalizeWebDAVConfig()`。未配置状态可以保留空服务器；真正构造客户端时必须有有效服务器。

服务器只接受 HTTP/HTTPS 且必须具有 authority。允许保留 Nextcloud 等服务的基础路径，但拒绝
user-info、query、fragment、反斜杠、控制字符、空路径段、dot segment，以及解码后会成为 `/` 或
`\` 的编码段。Basic Auth 用户名拒绝 `:`，避免显示身份与服务器解析身份不一致。HTTP 只有在用户
明确确认后才允许，HTTPS 不保存无意义的 HTTP 授权标记。

备份路径规范存储为首尾带 `/`、每段经过一次解码校验再规范编码的形式。建目录、批次目录、对象和
manifest URL 都从同一组解码段生成。设置页显示可读路径，但保留字面百分号为 `%25`，保证显示、
保存、加载反复执行仍映射到同一远端资源。

所有附带 Basic Auth 的 HTTP 请求在统一 request 边界再次验证同源且位于配置服务器基础路径之下，
并拒绝 query、fragment、控制字符、反斜杠、非法百分号和编码 dot segment。即使未来调用者误传公开
`remotePath`，也不会把凭据发送给跨域或基础路径之外的地址。

持久化读取严格拒绝非法记录，并在读取 AssetStore 密码前完成路径校验。若旧记录的 envelope 与
credential alias 仍可信、只是旧 URL/路径不再符合新规则，则允许用户用有效配置替换并安全回收旧密码，
避免升级后永久无法保存。

## 原因

旧实现分别用 `pathSegments()`、`backupUrl()`、设置页 trim 和事务默认值处理同一配置。重复 `/`、
dot segment、反斜杠或编码分隔符会令 MKCOL 与 PUT 指向不同层级；带 query/fragment 或非 HTTP(S)
服务器也会进入持久化，直到网络操作才失败。更危险的是重复解码百分号可让 `%252F` 在多次保存后
变成路径分隔符。

Android 原版 1.0.3 没有 WebDAV 客户端可逐行移植。本项依据 RFC 3986 的 URI 分层与百分号编码、
RFC 4918 的 WebDAV collection 资源语义，以及 Harmony `url.URL`/HTTP API 契约实现，不虚构原版逻辑。

## 边界

真实 Nextcloud、Apache mod_dav 等服务端对 Unicode、端口、重定向和 MKCOL 的互操作仍需设备与真实
服务器矩阵验证。本决策不把 WebDAV 凭据放入 URL；用户名和密码仍独立通过 Basic Auth 与 AssetStore
管理。
