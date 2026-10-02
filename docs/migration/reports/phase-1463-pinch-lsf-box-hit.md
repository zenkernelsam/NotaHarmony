# Phase 1463 报告：utf 捏合界内判定 lsf 支 = 元素包围盒（guf.y rtf/mp4.e()/sbe.a）

## 原版行为（1.4.2 证据）

`guf.y`（guf.java:1300-1360）utf 会话建立门全解码：

- `h==null` 才启动；`i!=null`（其它会话）→ `g.p(otf.a)` 取消后拒。
- 选区 id 匹配、`!(lsf && lsf.c)`（裁剪会话标记——CROP 处置 true，
  urf/pob 收尾置 false）、`!w(msf)`（全锁）、`!(isf && isf.h)`
  （isf.h=deselectMode）——四重门。
- 界内判定按选区类型分构造 `rtf(sbe 界, 反旋矩阵)`：
  - **ksf**（isf 集合/jsf 组）：`rtf(ksf.a() 选区界四边形,
    f5n.c(u64.b(ksf.a()), −fq9.f0(g())))`；
  - **lsf**（单元素）：`xnm.d(hv6, zq.m(位置), false)=mp4` →
    `rtf(mp4.e() 元素包围盒, mp4.c()≠0 ? f5n.c(mp4.b(), −c()) : null)`；
  - **hsf**（进行中套索）：rtf=null → 不启动。
- 判定点经 `f5n.g(点, rtf.a())` 反旋后 `sbe.a` 半开包含
  （`x≥l && x<r && y≥t && y<b`）；`i(msfVar)` 原位置图非空 →
  `new utf(id, mapI, j,j,j, msf)`。

**关键语义**：lsf 测的是元素**旋转包围盒**（mp4.e()），不是元素
几何轮廓——对角线笔画盒角内第二指照样启动捏合。

## Harmony 缺口（Phase 1457 登记）

`tryStartSelectionPinch` 单元素支复用 `topmostPageElementIdAt`
（笔画距离场/形状路径几何精确命中）——包围盒角域漏启动。

## 实现（NoteCanvasView.ets）

- `tryStartSelectionPinch`：单元素 lsf（无组·`!supportsDeselectMode`·
  总数==1）分流 `singleElementBoxHit(secondCanvas)`；其余走
  `pointInSelectionRect`（ksf.a() 等价路径）。
- `singleElementBoxHit`：逐类型局部界 + transform →
  `pointHitsAffineBlock`（逆变换+半开包含 = `f5n.g+sbe.a` 等价，
  顺带覆盖缩放）：笔画/形状 `.bounds`，文本/图/数专用 localBounds。

## 验证

- `d02-original-pinch-session-utf.mjs`：22→24 项（lsf 盒支 +
  逐类型界源断言）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾验证。

## 遗留差异

- 笔画旋转烘进点列 → AABB 界略大于原版旋转盒（斜笔画角域多命中），
  登记不纠（数据模型差异）。
- 本 Phase 顺带坐实 `em4.F`=空集——P1460「射线辅助线未画」实为
  原版本就清导线，非差异。
