# Harmony 证据：原版大图四分之一旋转缩放顺序

日期：2026-08-25
范围：`note/src/main/ets/data/OriginalImageNormalizer.ets`

## 平台证据

- DevEco SDK `@ohos.multimedia.image.d.ts` 定义 `DecodingOptions.rotate` 为像素图旋转角度、`desiredSize` 为期望宽高，但未说明二者与 EXIF 方向的组合应用顺序。
- 同一头文件定义 `PixelMap.rotate(angle)` 与 `PixelMap.scale(x, y)`，可在解码后显式控制变换顺序。

## 原版证据

- `vuh.java:66-67` 先根据 EXIF 是否为 90°/270° 交换门限轴。
- `vuh.java:72` 的 Float32 比率仍使用编码轴最大值计算。
- `w34.java` 将 EXIF 3/4、5/8、6/7 映射为 180°、270°、90°。

## 实现结果

- 解码阶段仅保留 `sampleSize` 与 `editable`，不再组合 `rotate` 和 `desiredSize`。
- 解码后先 `rotate()` 再 `scale()`，随后校验最终宽高等于原版计划。
- Float32 除法边界保持 `Math.fround()`，非法比例 fail-closed。

## 验证

- 新增 Replay：`D02_ORIGINAL_QUARTER_TURN_SCALE_ORDER_OK TOTAL=9 FAILED=0`。
- 更新既有大图 Replay：`D02_ORIGINAL_LARGE_IMAGE_NORMALIZATION_OK TOTAL=18 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=364 PASSED=364 FAILED_FILES=0`。
- clean 成功 2.488 秒；ohosTest HAP 成功 9.220 秒；default HAP 成功 30.970 秒。
