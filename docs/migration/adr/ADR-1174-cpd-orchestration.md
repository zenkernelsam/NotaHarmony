# ADR-1174：cpd GL 画布编排

## 状态

已接受（Phase 1230）。

## 决策

`cpd` GLSurfaceView+GAME_ROTATION_VECTOR+`bpd`/`aaf`/
`vfc`/`ev9` 三职责编排 → Harmony `XComponent` + sensor +
渲染/触控/媒体节点分层。

## 理由

`cpd` 构造：sensor 15→11、`ev9(display,aaf,bpd)` 双
监听、`vfc N`=nc1+zxf、`setDefaultStereoMode`→`vfc.S`、
sensor `Q&&R` 门控 —— 完整 GL 画布编排。

## 后果

Harmony GL 画布 = XComponent+GAME_ROTATION_VECTOR+
渲染器+触控+媒体节点 —— 编排语义保真。
