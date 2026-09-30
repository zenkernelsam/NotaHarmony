# ADR-1139：手势→渲染桥 + 输入模态 + 传感

## 状态

已接受（Phase 1195）。

## 决策

- `aaf`=`GestureDetector`→`bpd` SceneRenderer
  （onDown/onScroll/onSingleTapUp→平移/选择）→
  Harmony `PanGesture`/`TapGesture`/`Gesture`。
- `jqa` 3 值输入-模态 enum → Harmony 输入模式 enum。
- `ev9` SensorEventListener 旋转矩阵（`nc1` 相机）→
  Harmony `@ohos.sensor`。

## 理由

`SimpleOnGestureListener`+`OnTouchListener`+`dv9` +
`bpd`+`GestureDetector`+PointF + `jqa{I,J,K}` +
`ev9{float[16]}` SensorEventListener。

## 后果

Harmony 手势 = Gesture 组件回调→渲染；传感旋转
→sensor→相机矩阵；输入模态 enum 保留。
