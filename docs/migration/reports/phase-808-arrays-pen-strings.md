# Phase 808 报告：arrays/pen_string 面收口 + Rive 谱系更正

日期：2026-09-23
Phase 类型：证据登记与更正（无功能代码改动）

## 摘要

收口 `res/values/arrays.xml` 与 `pen_string_*` 字串族残余面，并更正
Rive 运行时版本谱系（1.0.3 存量 `app/rive` 256 文件 → 1.4.2
`app/p000rive` 485 文件，非新增）。

## 发现

- `feature_learn__chat_card_headers`：7 条 Learn AI 聊天卡片轮换
  引导语（fail-closed 边界内数据，登记）。
- `pen_string_*` 8 keys：笔设置面板标签族，含
  `fixed_thickness`/`variable_thickness` 压感响应模式开关文案——
  Harmony 已有压感管线但无此模式开关，登记为笔设置面差异。
- `arrays.xml` 数组名清单两版完全一致（70 项）。

## 更正

Phase 791 暗含"Rive 属 1.4.2 新增"——实际 1.0.3 已内置
`app/rive/`；1.4.2 为包名混淆化（`p000rive`）+ 运行时大版本升级。
`.riv` 资产 6 件两版同名同内容。

## 验证

- `d02-arrays-pen-strings.mjs`：5/5 green
- 全量套件与双 HAP：见提交

## 产物

- 证据：`docs/migration/evidence/phase-808-arrays-pen-strings.md`
- Replay：`docs/migration/replays/d02-arrays-pen-strings.mjs`
- ADR：`docs/migration/adr/ADR-0752-arrays-pen-strings.md`
