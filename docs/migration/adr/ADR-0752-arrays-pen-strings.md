# ADR-0752：arrays/pen_string 残余面登记与 Rive 谱系更正

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-808-arrays-pen-strings.md`
- Replay：`docs/migration/replays/d02-arrays-pen-strings.mjs`

## 决定

`arrays.xml` 残余数组与 `pen_string_*` 标签族登记为证据；
"固定/可变粗细"模式登记为笔设置面差异，暂不实现；
更正 Rive 运行时为 1.0.3 存量 + 1.4.2 升级（非新增）。

## 依据

- `feature_learn__chat_card_headers`（7 条轮换引导语）属 Learn
  AI 卡片面——fail-closed 边界内数据。
- `pen_string_*` 8 keys 含 `fixed_thickness`/`variable_thickness`——
  每工具"压感响应模式"开关文案；Harmony 已有压感管线但无该模式
  开关，属 S Pen 语境的笔设置面板差异，登记待后续评估。
- Rive 运行时 1.0.3 已存在（`app/rive/` 256 文件），1.4.2 为
  混淆改名（`p000rive`）+ 版本升级（485 文件）；`.riv` 资产
  两版同名同内容 6 件——修正 Phase 791 的"1.4.2 新增"口径。

## 影响

资源面残余证据闭合；Rive 谱系更准确（存量升级）；fixed/variable
thickness 进入差异登记册。
