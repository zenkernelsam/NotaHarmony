# 原版大图规范化证据（Phase 281）

## 1. 证据范围

本阶段只读取 Desktop `decompiled_1.0.3/sources/defpackage/vuh.java` 和 `w34.java`；所有源码、测试、Replay
与文档写入正式仓。未启动模拟器、虚拟机、真机或 Hypium。

## 2. 文件哈希

| 文件 | SHA-256 |
|---|---|
| `decompiled_1.0.3/sources/defpackage/vuh.java` | `00D902C109245A8B702272AB17173581068FD064B5B1797B47E01222E47D497D` |
| `decompiled_1.0.3/sources/defpackage/w34.java` | `8CD08C868F2081EDDB23DEF19DE5060CF7F7495FA0E434D6CCEFCB5E39433068` |

## 3. EXIF orientation 映射

`w34.java:978-991`：

```java
switch (c(1, "Orientation")) {
    case 3:
    case 4:
        return 180;
    case 5:
    case 8:
        return 270;
    case 6:
    case 7:
        return 90;
    default:
        return 0;
}
```

`vuh.java:64-67` 对 rotation 90/270 交换对外宽高：

```java
boolean z = iL == 90 || iL == 270;
int i3 = z ? i : i2;
int i4 = z ? i2 : i;
```

因此 Harmony 的计划必须以 oriented 宽高判断 3000px 门禁，但 sample size 的除法仍按原 encoded 轴执行。

## 4. 缩放、旋转与重编码

`vuh.java:69-86` 固定边界与采样循环：

```java
if (i3 <= 3000 && i4 <= 3000) {
    return ep5Var;
}
float fMax = 3000.0f / Math.max(i2, i);
int iY0 = m18.y0(i2 * fMax);
...
while (true) {
    int i8 = i7 * 2;
    if (i2 / i8 < i5 || i / i8 < i6) break;
    i7 = i8;
}
options2.inSampleSize = i7;
```

`vuh.java:113-137` 继续实际缩放、旋转和重编码：

```java
Bitmap bitmapCreateScaledBitmap =
    Bitmap.createScaledBitmap(bitmapDecodeFile, i5, i6, true);
...
matrix.postRotate(iL);
bitmapCreateBitmap = Bitmap.createBitmap(...);
...
bitmapCreateBitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 85, fileOutputStream);
...
return new ep5(..., ..., "image/webp");
```

这证明大图路径必须整体替换字节、MIME、fileSize 和 dimensions；不能只改 CREATE_BLOCK metadata。

## 5. Harmony 对齐点

- `planOriginalImageDownscale()` 用 `Math.fround(3000 / max(encodedWidth, encodedHeight))` 复现 float ratio，
  half-up 目标尺寸，power-of-two sample size 与 Android 相同。
- adapter 先读 header/ORIENTATION，再计算 oriented dims；需要规范化时传入 `sampleSize`、`rotate`、
  `desiredSize` 和 `editable:true`。
- `ImagePacker.packing(..., format:'image/webp', quality:85)` 对应原版 lossy 85。
- 编码失败进入外层异常并释放资源；没有 supportedFormats 伪装成功。
- persistence normalization 返回值同时携带 bytes、MIME、encodedWidth/Height，供后续完整资产门禁使用。

## 6. 静态证明边界

专项 Replay 覆盖原版源码片段、adapter 关键链路、fixture 注册与数值模拟。它不能证明真实设备 ImageKit 对
所有容器/EXIF 变体的解码行为，也不能证明 WebP 编码色彩、透明度、内存峰值和产品端到端结果。