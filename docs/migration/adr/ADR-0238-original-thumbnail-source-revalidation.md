# ADR-0238：缩略图发布前重校验首页 Source Revision

## 状态

Accepted - Phase 260（2026-08-17）

## 背景

重放 M2-R-06 后发现总纲中“没有共享 renderer、并发限制、generation 或缓存上限”的现场已过时：主画布与
缩略图已共享 stroke/text/shape/image/math/tape/paper/PDF rendering contract，Library 已有 3 worker、64 项上限、
generation/lifecycle 门禁和 renderer 互斥退役。

仍存在的真实竞态是：Library 先读取首页 revision，随后另一次异步加载元素和资产并渲染，最后直接把结果与最初
revision 发布。渲染期间若首页、内容、背景或 asset generation 改变，PixelMap 可能来自混合 source；渲染失败时
旧逻辑还会无条件保留旧 bitmap，即使其 revision 已落后。

原版 `cn7/if9/h59/m6j` 把 bitmap 与 `onDiskOpId` 成对发布，并且只有 produced opId 非空且不落后于调用方
expected opId 时才把 bitmap 交给 UI。Harmony 必须保留“图片与 source identity 不可拆分”和“已知过期图必须
隐藏”这两个产品语义。

## 决策

- 使用首页 `pageId` 与完整 thumbnail cache revision 作为一次渲染的 source identity；revision 继续包含页面
  内容/背景签名、主题纸色/线色和 asset generation。
- 新增 `isThumbnailSourceUnchanged()`；不得对拼接 revision 做大小比较，只允许 pageId 非空且完整 identity
  精确相等。
- 每篇笔记最多进行两次 source attempt：读取 source、渲染、重新读取 source；相同才发布 PixelMap/revision。
- source 在第一次渲染期间变化时，释放未发布 PixelMap，并以最新 source 重试一次；第二次仍变化则显示占位，
  等后续正常 refresh，不进行无界循环。
- 每次 render 后仍先检查 thumbnail generation、页面 lifecycle、pageActive 与 renderer identity；source
  revision 是内层数据门禁，不替代既有并发/lifecycle 门禁。
- 渲染或验证失败时，只有旧 PixelMap 的 revision 被再次证明与当前 source 完全相同才允许保留；否则不写入
  `newMap`，让 UI 显示占位，不展示已知过期图。
- 通过单一异步 release helper 清理未发布、过期、被替换和页面退出的 PixelMap，并记录但吞掉 release 自身
  异常，避免一个 native 清理失败阻止其余缓存收口。
- 不新增持久化 thumbnail 文件、不增加 worker 数、不扩大 64 项缓存，也不把设备像素/内存验收伪装成静态完成。

## 后果

- 编辑首页、页面重排、背景变化或资产落地与缩略图渲染并发时，旧 attempt 不能再把混合/过期 PixelMap 配到
  新列表。
- source 高频变化最多浪费两次渲染和两次未发布 PixelMap，之后安全退回占位；不会形成无限 rerender loop。
- 渲染失败不再以“看起来有图”为理由保留已知过期内容，行为更接近原版 `m6j` 的 opId validity gate。
- 每个 cache hit 仍由当前第一次 source 读取确认；数据库变化后的最终 UI 时序仍依赖既有 refresh/generation
  通知，设备级快速同步和滚动需继续验证。

## 验证契约

- `ThumbnailRenderPolicy.test.ets` 覆盖相同 source、revision 改变、首页改变与空 page identity。
- `d02-original-thumbnail-source-revalidation.mjs` 固定原版 bitmap/opId 配对证据、两次 source 读取、有界重试、
  过期释放、失败隐藏与异步 release 门禁。
- `d02-thumbnail-cache-pair.mjs` 继续保证 cache hit 与新渲染均成对发布 PixelMap/revision。
- Library query/mutation、Image、Paper、PDF thumbnail 专项和全量 replay 必须通过。
- clean 后 `note@ohosTest` 与 `note@default` 必须严格串行构建；不启动设备、模拟器、虚拟机、真机或 Hypium。

## 仍需设备验收

- 编辑首页后立即返回资料库，旧图不得闪回；快速切换 folder/search 时旧 worker 不覆盖新列表。
- 同步/资产落地与滚动并发时占位、重试和最终图片稳定性。
- 100 篇笔记滚动后的 PixelMap 数量、native/JS 内存峰值、release 失败日志与主画布/缩略头像素一致性。
