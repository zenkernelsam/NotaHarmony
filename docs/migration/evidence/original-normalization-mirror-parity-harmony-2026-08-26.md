# Harmony 证据 — 原版大图归一化镜像一致性

- 原版证据：
  `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\vuh.java`
- 原版事实 1：只有 oriented 尺寸超过 3000px 才进入 decode/downscale/re-encode；
  矩阵仅执行 `matrix.postRotate(iL)`，没有 `postScale(-1, 1)`。
- 原版证据：
  `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\w34.java`
- 原版事实 2：`w34.l()` 把 Orientation 映射成 90/180/270 度，丢弃水平镜像位。
- 归一化边界：`vuh.b()` 的重编码矩阵只有旋转；显示端 `g3.java` 的 2/4/5/7
  镜像逻辑不能迁移到持久化字节。
- 原版证据：
  `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\g3.java`
- 原版事实 3：`g3.java` 的显示解码器单独识别 2/4/5/7 并做水平镜像；但 vuh 重编码
  WebP 不携带原 EXIF，后续 g3 无法恢复被丢弃的镜像。
- Harmony 事实：`OriginalImageNormalizer.ets` 只在 oriented 尺寸越过 3000px 门限时
  重写 WebP，当前也只调用 `pixelMap.rotate(rotationDegrees)`；阈值内即使存在非零
  EXIF 旋转也保留原始字节，显示端由 `ImageAssetLoader` 应用完整 2/4/5/7 镜像集合。
- 审计结论：这不是 Phase 444 遗漏，而是原版同源限制；Phase 528 进一步修正
  小图 rotation-only 误重写，Replay 锁定“显示补镜像、归一化不补镜像”的边界。
- 原版同源限制：超大镜像图经 `vuh.b()` 重编码后只保留旋转，不保留水平镜像。
