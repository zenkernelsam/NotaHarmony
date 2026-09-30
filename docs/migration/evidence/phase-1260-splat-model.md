# Phase 1260 证据（里程碑）— mea/lea 铅笔 splat 图集模型

来源：`defpackage/{mea,lea,a,owd}.java`。

## `mea` = splat 印章实例

```java
static ByteBuffer j;             // 共享空缓冲
static float k = sqrt(2);        // AA（√2 抗锯齿）
lea a;                           // 图集
int b;                           // color
ByteBuffer c; int d,e;           // 顶点/索引缓冲
float f,g,h,i;                   // pos(x,y)+rotation+size
```

## `lea extends a` = splat 图集

`a` 持有 `static byte[]` —— **烘焙的 splat 图集纹理
字节**（铅笔纹理颗粒）。

## `owd.splats = List<mea>`

PencilStrokeContent 的 splat 列表 —— **铅笔 = 印章序
列**：每 `mea` 以 pos/rot/size 采样 `lea` 图集 → GL
纹理印章。

## 语义

- `mea` = **单个 splat 印章**（图集+颜色+位置/旋转/大小）；
- `k=√2` = 45° 旋转抗锯齿系数；
- `lea`/`a` = 共享 baked 图集（纹理字节）；
- `owd.splats` = 铅笔笔迹 = splat 印章序列 —— **铅笔
  颗粒感来自纹理印章**（非贝塞尔/中线）;
- 三类 stroke 渲染：`mwd` 贝塞尔、`nwd` 中线、`owd`
  splat（Phase 1183）—— pencil 走 splat 管线。

## Harmony 决策

splat 图集+印章 → Harmony GL 纹理图集+印章 mesh —
— 铅笔颗粒语义保真。

## 产出

- fixture `d02-splat-model.mjs`（10 断言）。
- ADR-1204；中文报告。
