# ADR-1204：mea/lea 铅笔 splat 图集

## 状态

已接受（Phase 1260 里程碑）。

## 决策

`mea` splat 印章+`lea`/`a` 烘焙图集+`owd.splats` →
Harmony GL 纹理图集+印章 mesh。

## 理由

`mea`={图集+color+pos/rot/size}，`k=√2` AA；`lea`/`a`=
baked byte[] 图集；`owd.splats`=`List<mea>` —— 铅笔=
印章序列（颗粒感渲染）。

## 后果

Harmony 铅笔 = 纹理图集+印章 —— 铅笔颗粒语义
保真。
