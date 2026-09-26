# 原版 1.4.2 画廊社区产品面登记（Phase 774 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/res/values/strings.xml`
>   `feature_library_gallery__*` 键族 + `data/gallery/` 包
> 性质：1.4.2 版本差证据登记（ADR-0708 画廊簇细化）；无 Harmony 代码变更。

## 一、键族规模

`feature_library_gallery__*` 共 **131 键**（1.0.3 为零）——
完整社区产品面，按前缀聚类：

| 子面 | 键数 | 代表键 |
|---|---|---|
| 社区准则 | 18 | `guidelines_*` |
| 内容举报 | 15 | `report_reason_{spam,abusive,sexual,dmca,other}`、`report_profile_area_{avatar,bio,links,multiple}`、`reported` |
| 用户资料 | 11 | `profile_*`（avatar/bio/links/screenname） |
| 发布/编辑 | 8+ | `edit_*`、`unpublish`、`quarantined`、`awaiting_review` |
| 收藏集 | 8 | `collection`、`my_collections`、`official_collections`、`add_to_collection` |
| 社交动作 | 5+ | `follow_action`、`followers_title`、`likers_title`、`following` |
| 评论 | 5 | `comment_*` |
| 发现/搜索 | — | `discover_empty`、`popular_tags`、`recent_searches`、`more_like_this`、`inspired_by` |
| 邮箱验证 | — | `unverified_email`、`verification_sent`、`resend_verification` |
| 其他 | — | `templates_row`、`view_remixes`、`by_publisher`、`download_failed`、`change_photo` |

## 二、产品语义

完整社区闭环：发布笔记 → 审核队列（`awaiting_review`/`quarantined`）
→ 画廊展示（tabs/discover/tags）→ 互动（like/comment/follow）→
remix 谱系（`inspired_by`/`view_remixes`/`remixes_title`）→
收藏集 + 举报 + 资料页。邮箱验证为发布前置。

## 三、Harmony 分类

全部后端耦合——发布/审核/搜索/互动/谱系均依赖 GingerLabs 画廊
服务与账号体系。维持 ADR-0708 fail-closed；本阶段仅固化
产品面规模（131 键 × 十子面）为 T-042 输入。

本地 outbox（Phase 766）是该面的唯一本地残迹。
