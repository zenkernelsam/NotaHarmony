# ADR-0195：Math 位图缓存必须释放完整所有权并隔离超预算条目

## 状态

Accepted，2026-08-14。

## 问题

`MathCanvasRenderer` 已有 4 MiB LRU 和 `clear()`，但资源所有权存在三个缺口：

- 主编辑器的 `disposeRenderingResources()` 从不调用 `mathRenderer.clear()`；
- `ThumbnailRenderer.dispose()` 也不清空 Math cache；
- 淘汰和 clear 只调用 `PixelMap.release()`，没有关闭由它创建的 `ImageBitmap`。

因此反复进入编辑器、离开资料库或替换缩略图 renderer 后，旧公式纹理可能继续持有 native 图形资源，直到不确定的
GC 时机。

另有一个即时使用后释放错误：新纹理先加入 cache 再执行 `evictCache()`。当单张纹理本身大于 4 MiB 时，LRU 会
把它自身移出并调用 `PixelMap.release()`，随后当前 `renderMath()` 仍用该 entry 的 `ImageBitmap` 执行
`drawImage()`。这会把“缓存超预算”变成已释放纹理绘制、空白公式或平台异常。

## 原版与平台证据

- `decompiled_1.0.3/sources/defpackage/w18.java` 创建容量为 `4194304` 的公式 LRU。
- `decompiled_1.0.3/sources/defpackage/v18.java` 以 `bitmap.width * bitmap.height * 4` 计算条目字节数。
- `decompiled_1.0.3/sources/defpackage/p18.java` 在 `nativeDraw()` 失败时立即 `Bitmap.recycle()`，说明失败或不再拥有
  的公式位图不能继续留作可绘制对象。
- Harmony `PixelMap.release()` 与 `ImageBitmap.close()` 是两层显式资源所有权。Android Bitmap 的 GC/LRU
  行为不能直接替代 Harmony 对这两个对象的释放责任。
- `LibraryPage.retireThumbnailRenderer()` 已通过 `thumbnailRefreshMutex` 等待活动缩略图工作退出后再 dispose，
  因而可以安全清空该 renderer 的公式 cache。

## 决策

1. 保持原版 4 MiB byte-counted LRU 上限不变。
2. 新公式纹理只有在自身字节数不超过 cache 上限时才加入 LRU；单张超预算纹理作为 transient texture 使用。
3. transient texture 必须保持有效直至当前 `drawImage()` 完成，并在 `finally` 中立即释放；无论绘制成功或抛错，
   Canvas 状态和纹理所有权都要收敛。
4. `ctx.save()` 后的 transform/draw 使用 `try/finally`，确保 `ctx.restore()` 不被绘制异常跳过。
5. 新增统一 `releaseTexture()`：先关闭 `ImageBitmap`，再异步 release `PixelMap`；close 异常不能阻止 PixelMap
   释放。
6. LRU 淘汰与 `clear()` 都必须调用同一个完整释放 helper，不能只释放其中一层对象。
7. `NoteCanvasView.disposeRenderingResources()` 清空主画布 Math cache。
8. `ThumbnailRenderer.dispose()` 在销毁 stroke renderer 和 pencil PixelMap 前清空缩略图 Math cache。
9. `clear()` 保持幂等：释放全部 resident texture 后重置条目数组和字节计数，允许生命周期回调重复收敛。

## 结果

- 页面或缩略图 renderer 退场时，公式 `ImageBitmap + PixelMap` 不再依赖 GC 才回收。
- LRU 淘汰和显式 clear 使用一致的所有权结束路径。
- 单张超过 4 MiB 的公式仍能完成当前帧绘制，但不会污染有界 cache，也不会在绘制前被自己淘汰释放。
- 绘制异常不再泄漏 Canvas save/restore 状态或 transient texture。
- 正常 4 MiB 内的公式缓存命中、LRU 顺序和视觉输出保持不变。

## 边界

- `PixelMap.release()` 是异步 Promise；当前同步 renderer 只能发起释放并吞掉重复/迟到错误，设备端实际 native
  内存下降时点仍需分析器观察。
- 真实超大 Math block 受 native 4096 边长和 16 MiB bitmap 预算约束；仍需设备样本确认 draw 后立即 close 不会
  与平台延迟合成产生竞争。
- 本决策处理 ArkTS 图形对象生命周期；native `OH_Drawing_Bitmap/Canvas` 在异常路径中的 RAII 仍是独立审计项。
