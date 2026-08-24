# ADR-0384：原版大图四分之一旋转缩放顺序

- 状态：已接受（2026-08-25）
- 场景：原版 `vuh.b()` 在 EXIF 旋转前使用编码轴执行 3000px 门限与 `inSampleSize` 计算；90°/270° 时最终输出轴交换。Harmony 旧实现把 `rotate` 与 `desiredSize` 同时交给 `createPixelMap()`，但 SDK 未定义两者组合顺序，不同平台可能先按目标轴裁剪或缩放再旋转，导致输出尺寸或内容错误。
- 决策：保留原版按视觉轴门限后的编码轴采样计划；解码时不传 `desiredSize` 与 `rotate`。解码得到可编辑 PixelMap 后，先调用 `PixelMap.rotate()` 应用 EXIF 旋转，再调用 `PixelMap.scale()` 按计划尺寸显式缩放，并在每一步校验实际轴。
- 结果：90°/270° 超大图不再依赖未定义的解码参数组合顺序；采样语义与 Android 原版一致，旋转与缩放顺序在 Harmony 内确定，异常继续 fail-closed 并释放资源。
