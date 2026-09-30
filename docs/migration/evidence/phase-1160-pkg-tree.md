# Phase 1160 证据 — com.gingerlabs.notability 全包树（架构盘点）

来源：`com/gingerlabs/notability/` 命名包全目录（milestone）。

## 包树

```
app/                    app/initializers  app/widgets
core/                   analytics  common/{logging,memory}
                        flatbuffers  glmath  model  network
                        retrofit  user
data/                   billing/{client,gateway}
                        handwritingrecognition
                        learn/database
                        library/state/{database,folders,notes,ntb}
                        note/{assets,ops/{database,synced},state}
                        samsungbilling/{client,gateway}
                        search/{database,engine/room}
                        settings/database  stylus/haptic
                        subscription/storage  theme
                        toolbar/database
                        transcription/{database,livetranscription,upload}
domain/                 subscription
feature/                login/{apple,microsoft}
                        note/toolbox/audio/record/wrapper
ui/                     fileimport/{data,importer}  support/data
```

## 分层

- **app** = 应用入口 + 初始化器 + 桌面 widget。
- **core** = CRDT 模型 + FlatBuffers + glmath + 网络 +
  retrofit + 分析 + 用户 —— 与 `defpackage` 混淆核心对应。
- **data** = Room DB + 仓储层（library/note/search/settings/
  toolbar/transcription/stylus/subscription/billing/learn/
  handwriting-recognition）—— Android Room + 后端。
- **domain** = subscription 领域。
- **feature** = 登录(apple/microsoft) + note toolbox 音频
  录制。
- **ui** = 文件导入 + 支持 UI。

## 迁移边界

- **core 已映射**（defpackage CRDT/FB/glmath）。
- **data/\*** = Room/SQLite + 后端仓储 → Harmony 需
  `@ohos.data.relationalStore` 等价 + fail-closed 后端。
- **feature/login/{apple,microsoft}** = OAuth —— 平台相关。
- **billing/samsungbilling/subscription** = 商店支付 ——
  fail-closed（Harmony IAP 不同）。
- **stylus/haptic** = 手写笔触觉 —— Harmony 触控笔 API。
- **transcription** = 转录上传 —— 后端。
- **handwritingrecognition** = iink 适配（Phase 1159
  fail-closed）。

## Harmony 决策

- data/ → relationalStore 仓储 + 后端 fail-closed。
- feature/login/billing/subscription → 平台支付/OAuth
  fail-closed；stylus/transcription 需适配层。

## 产出

- fixture `d02-pkg-tree.mjs`（10 断言）。
- ADR-1104；中文报告。
