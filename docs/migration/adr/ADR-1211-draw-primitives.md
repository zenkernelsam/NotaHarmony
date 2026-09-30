# ADR-1211：DrawScope 绘制图元

## 状态

已接受（Phase 1267）。

## 决策

`xd1` CanvasDrawScope+`po3`/`f31`/`qu1`/`bt` 画刷/
Paint → Harmony `CanvasRenderingContext2D`+`LinearGradient`
+`colorFilter`。

## 理由

`xd1`=CanvasDrawScope（`bt` Paint 池+`b40`/`wd1`+
draw 调用 drawRect/Circle/Line/Image）；`po3`=Brush/
`f31`=ShaderBrush/`qu1`=ColorFilter/`bt`=Paint ——
Compose 图形图元。

## 后果

Harmony 绘制 = CanvasRenderingContext2D+渐变+色彩滤镜
—— 图元语义保真。
