# ADR-1377: 选择菜单剩余四项 fail-closed/死项裁决——wqf/urf 轴收口

- 状态：已接受
- 日期：2026-08-09
- 关联：ADR-1374/1375/1376（urf 装配链）、ADR-0645（菜单项总登记）

## 决策

| 原版项 | 裁决 | 证据 |
|--------|------|------|
| CONVERT_TO_MATH | fail-closed | h45.b(h35.e0)=td5 `androidMathHandwritingRecognition` defaults=false + iink 私有 |
| CONVERT_TO_TEXT | fail-closed | 行门=全 mn7+任一非 HIGHLIGHTER（oim.b），分发链入 MyScript iink |
| SAVE_AS_STICKER | fail-closed | h45.b(h35.z0)=STICKERS rd5 InternalUserOnly 生产恒不可达 |
| FIT_TO_PAGE | 原版死项 | wqfVar17 未赋静态字段；urf 无 add 点；m36 case16 死支；1.0.3 dhb case15=NotImplementedError |

Harmony 侧四项全部缺省——经复核为正确终态，**不新增代码**，
仅将裁决证据固化于 overlay 注释与本 ADR。

## 后果

- `wqf`/`urf` 选择菜单轴 23 项全部裁决完毕（19 已移植/合并 + 4 关闭）。
- 未来若 iink 等效引擎或旗标语义变更需重开，以本 ADR 为基线。
