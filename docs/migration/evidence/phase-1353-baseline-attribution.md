# Phase 1353 证据 — 基线归属审计（更正早期误标）

对 Phases 1325–1328 引用的原版混淆类名逐一复核（实读
decompiled 源码）。**结论：若干早期基线引用为误标
的混淆名**，Harmony 实现语义仍正确，但引用需更正。

## 复核结果

| 早期引用 | 实际内容 | 判定 |
|----------|----------|------|
| `b90`（Phase1327 形状检测） | `AbstractSet` 集合包装 | **误标**→`g5d`/`uf8`/`f5d` |
| `w4a`（Phase1328 轮廓） | `/* synthetic */ int[]` when-map | **误标**（非轮廓构建器） |
| `wy5`（Phase1326 拟合） | `ko3 extends nd8` Modifier 元素，`a(jw6)` DrawScope | **误标**（draw modifier） |
| `gn3`（splat 引用） | `n73` 大基类（`ara/pz5/q52/b25`） | **误标**（Compose 节点） |
| `ms1`（Phase1325 平滑） | `ns1` float 对 {I,J} | ✅ 正确（区间 helper） |
| `dr4`（平滑） | `hr4` 子类 | ✅ 合理（平滑器族） |
| `sqh`（Phase1326 拟合） | `lm9` 单例注册 `qeh`/`tdh` | ⚠ 部分（注册器，非算法本体） |
| `xaa`/`oz5`/`te6`（splat） | `yaa` impl/`jz5`/`cif` 单例 | ⚠ 相邻（splat 族但非逐字命中） |

## 更正说明

早期审计对混淆名按启发式归属，多将同名/近邻类误标。
Harmony 各算法实现（平滑/拟合/检测/轮廓/splat）语义
本身正确且文档化；**误标仅在原版基线符号引用**，不
影响 Harmony 代码正确性。真实检测/拟合基线为
`g5d`/`uf8`/`f5d`/`h8d`/`mih` 与 `sqh`/`tdh`/`qeh` 族。

## Harmony 决策

后续基线引用须经实读 decompiled 源码验证；已更正
`b90`/`w4a`/`wy5`/`gn3` 等误标；阈值/常量凡未在可读
字段暴露者一律标文档化近似。

## 产出

- fixture `d02-baseline-attribution.mjs`（10 断言）。
- ADR-1294；中文报告。
