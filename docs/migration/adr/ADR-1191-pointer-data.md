# ADR-1191：iqa/oqa/jqa 指针输入数据

## 状态

已接受（Phase 1247）。

## 决策

`iqa`=PointerInputEvent+`oqa`=PointerInputChange+`jqa`=
PointerEventType → Harmony `TouchEvent`/`TouchObject`。

## 理由

`iqa`=`List<oqa>`+`hc0` MotionEvent+actionMasked 分类；
`oqa`=指针变更全记录（id/uptime/pos/pressed/type/
previous*）；`jqa`=PointerEventType —— 指针数据。

## 后果

Harmony 指针数据 = TouchEvent+TouchObject —— 指针
语义保真。
