# ADR-1294：基线归属审计（更正误标）

## 状态

已接受（Phase 1353）。

## 决策

早期混淆类名基线引用逐一复核；更正 `b90`/`w4a`/`wy5`/
`gn3` 等误标，真实基线为 `g5d`/`uf8`/`f5d`/`h8d`/`mih`/
`sqh`/`tdh`/`qeh` 族。Harmony 实现语义不受影响。

## 理由

实读 decompiled 源码复核：`b90`=AbstractSet、`w4a`=
synthetic when-map、`wy5`=ko3/DrawScope modifier、`gn3`=
n73 节点基类 —— 均误标；`ms1`=float 对、`dr4`=hr4 族
正确；`sqh`=lm9 注册器（部分）；真实检测基线=
`g5d`(ShapeDetectorOutput)+`uf8`+`f5d`+`mih`。

## 后果

审计证据准确性提升 —— 更正误标混淆名；后续基线引用
必须经实读源码验证，常量凡未暴露者标近似。
