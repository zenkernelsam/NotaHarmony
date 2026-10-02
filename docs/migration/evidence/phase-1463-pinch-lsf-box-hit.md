# Phase 1463 — utf 捏合界内判定：lsf 元素包围盒（guf.y rtf/sbe.a）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### guf.java:y（约 L1300-1360）—— utf 会话建立门
```
if (this.h == null) {                    // 无进行中的 utf
    if (this.i != null) {                // 其它会话 → g.p(otf.a) 取消
        this.g.p(otf.a); return false;
    }
    msfVar = selection;
    id 匹配当前选区 &&
    (!(lsf && lsf.c)) &&                 // lsf.c=裁剪会话标记排除
    !w(msfVar) &&                        // 全锁定排除
    !(isf && isf.h) {                    // isf.h=deselectMode 排除
        // 界内判定 rtf(sbe 界, 反旋矩阵)：
        ksf (jsf/isf) → rtf(ksf.a(), f5n.c(u64.b(ksf.a()), −fq9.f0(g())))
        lsf → xnm.d(hv6, zq.m(位置), false)=mp4 →
              rtf(mp4.e(), mp4.c()≠0 ? f5n.c(mp4.b(), −mp4.c()) : null)
        hsf → rtf 为 null → 不启动
        rtf.b().a(f5n.g(j, rtf.a()))     // 点经矩阵反旋后 sbe.a 包含
          && (mapI=i(msfVar)).非空 → new utf(id, mapI, j, j, j, msf)
    }
}
```

### rtf.java / sbe.java / mp4.java
- `rtf` = (sbe 界, float[] 变换矩阵)；界内测 = `rtf.b().a(f5n.g(点, rtf.a()))`
  ——点先经矩阵变换（反旋），再做 sbe 矩形包含。
- `sbe` = (l,t,r,b) 浮点矩形；`sbe.a(p)` = `x≥l && x<r && y≥t && y<b`
  **半开包含**；`sbe.c()`=中心 (x 中点, bottom)。
- `mp4` = (j, sbe 界 b, float c() 旋转, boolean d() 锁)；`e()` 返回 sbe 界。
- lsf 支界 = `xnm.d(hv6 实体, zq.m 位置, false)` 产的 **元素包围盒**
  （mp4.e()），旋转 `mp4.c()`——**包围盒语义，非元素几何精确命中**。
- ksf 支界 = `ksf.a()` 选区界四边形（isf.d/jsf.g 旋转经 fq9.f0 归一）。

### 门字段核对
- `lsf.c` = 图像裁剪会话标记（sqf:59810 CROP 处置 true；pob:228/
  urf:127 收尾置 false）——Harmony `imageCropVisible→selectionVisible=
  false` 已等价排除。
- `isf.h` = deselectMode（isf.java toString 直证 `deselectMode=`）——
  Harmony `state.deselectMode` 门已等价。
- `w(msf)` = 全锁定 —— `selectionPositionLocked` 已等价。

## 差距（修复前）

`tryStartSelectionPinch` 对单元素 lsf 走 `pointInSelectionRect` 的
`topmostPageElementIdAt(canvasP)===id` 支——**元素几何精确命中**
（笔画距离场/形状路径）。原版测元素**旋转包围盒**：对角线笔画的
包围盒角部（远离笔迹）在原版可启动捏合，Harmony 漏判。

## Harmony 实现（本 Phase）

`NoteCanvasView.tryStartSelectionPinch`：单元素 lsf 分流到新
`singleElementBoxHit(canvasP)`——按类型取局部界 + 元素变换交给
`pointHitsAffineBlock`（逆变换+半开矩形包含 = sbe.a 逐点等价，顺带
覆盖缩放）：
- 笔画 `stroke.bounds + transform`；形状 `shape.bounds + transform`；
- 文本 `textBlockLocalBounds`、图像 `imageBlockLocalBounds`、
  数学 `mathBlockLocalBounds` + 各自 `transform`。

ksf 支（isf 集合/jsf 组）维持 `pointInSelectionRect`——其 drawnRect/
旋转系并集矩形路径与 `rtf(ksf.a(), −g())` 等价。

## 登记差异

- Harmony 笔画把变换旋转烘进 pathPoints（`transform` 恒等），其 AABB
  界比原版 mp4 旋转盒略大（细长斜笔画角域多命中）——数据模型差异，
  无旋转载体可用，登记不纠。
- 其余精确差异：sbe.a 半开（x<r、y<b 排右/下边）已由
  pointInHalfOpenRect 保持一致。

## 验证

- `d02-original-pinch-session-utf.mjs` 扩至 24 项（lsf 盒支 +
  逐类型界源断言）。
- 全量 Replay 1304/1304；`note@default`/`note@ohosTest` 构建通过。
