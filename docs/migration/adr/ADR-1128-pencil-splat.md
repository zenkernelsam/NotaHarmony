# ADR-1128：铅笔 splat 点阵渲染

## 状态

已接受（Phase 1184）。

## 决策

`owd`=`PencilStrokeContent{splats: List<mea>}` —— 铅笔
笔画渲染为**纹理 splat 点阵**（非路径填充）：每触点
`mea{lea 图集,color,pos/rot/size}` + `f(color,f)` RGB 通道乘
（压感深度）+ `k=√2` AA；`lea extends a` 共享烘焙
byte 图集 → Harmony 点精灵/纹理 stamp + 资源 rawfile
图集 + 颜色调制。

## 理由

`mea{lea,int,float×多}` + `sqrt(2)` + `f` 通道乘 + `a`
`byte[]` 烘焙图集。

## 后果

Harmony 铅笔 = splat 点精灵 stamp（压感=尺寸/深乘），
与路径笔画（Bezier/CentralPath）并列第三策略；图集
纹理进 rawfile/PixelMap。
