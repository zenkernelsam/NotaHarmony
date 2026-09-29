# ADR-1019：变换项校验 + 可选包装语义

## 状态

已接受（Phase 1075）。

## 决策

- `ie8` 校验 = `ddg.e` 三段短路：page+origin→rotation→scale；
  null 包装=不校验/不改。
- `k2d`(Float=rotation)、`y2d`(qed=scale) 可选包装区分
  "不改" 与 "改为零值"。
- `fsi.P` positionLocked 分流。

## 依据

`ddg.e` 链 + 包装类型 `j()` 访问。

## 后果

Harmony 保留 null-vs-零值语义；校验顺序一致（先 spatial
后数值）。
