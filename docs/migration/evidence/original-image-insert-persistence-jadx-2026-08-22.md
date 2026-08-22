# 原版图片插入几何、入口规范化与持久化证据（Phase 280）

## 1. 证据范围

本阶段只读取 `C:\Users\Cisco He\Desktop\Notability` 下的原版 1.0.3 反编译源码和临时 JADX
debug extraction；Harmony 代码、ADR、fixture、Replay 与报告均只写入
`C:\HarmonyProject\NotaHarmony`。未启动模拟器、虚拟机、真机或 Hypium。

## 2. 原版文件与哈希

| 文件 | SHA-256 |
|---|---|
| `decompiled_1.0.3/sources/defpackage/bvh.java` | `432FB846325FF4B53089E983B3FE6610AEE9267F275D9412581A7BD453A42025` |
| `decompiled_1.0.3/sources/defpackage/bgj.java` | `511F49014AFCD5782CAB0538752C4E9DA611D95F67020532786EDAF176DA6A12` |
| `decompiled_1.0.3/sources/defpackage/vuh.java` | `00D902C109245A8B702272AB17173581068FD064B5B1797B47E01222E47D497D` |
| `decompiled_1.0.3/sources/defpackage/w34.java` | `8CD08C868F2081EDDB23DEF19DE5060CF7F7495FA0E434D6CCEFCB5E39433068` |
| `.codex-tmp-phase280-yr-debug.java` | `CCE970FB9F6FD7A93AA9A72CBA62A865852746C3DA7F8BF407C7BB6883AE4B5B` |

其余 Phase 280 debug extraction 的完整账单保留到 handover；这些文件是逆向证据，不进入 Git。

## 3. 几何证据

`bvh.java:14-22`：

```java
float pageWidthLimit = pageWidth != null ? pageWidth.floatValue() * 0.8f : Float.MAX_VALUE;
float pageHeightLimit = pageHeight != null ? pageHeight.floatValue() * 0.8f : Float.MAX_VALUE;
float maxSide = maximumSide != null ? maximumSide.floatValue() : Float.MAX_VALUE;
float scale = Math.min(1.0f,
    Math.min(Math.min(pageWidthLimit, maxSide) / imageWidth,
             Math.min(pageHeightLimit, maxSide) / imageHeight));
return new lp5(imageWidth * scale, imageHeight * scale);
```

`bgj.java` 的 insertion path 把 maximum side 设为 `320.0f / zoom`。随后保留原图 `qedVar3`
作为 CREATE_BLOCK size，以 `display / intrinsic` 生成 scale；`bgj.java:128-131` 先从请求点减半显示尺寸，
再逐轴钳进页面，只有显示尺寸大于页面时才居中。

因此 Harmony 不能把 fitted display size 写回 intrinsic metadata，也不能先 clamp anchor 后再居中。

## 4. URI 与 100 MiB 边界

`.codex-tmp-phase280-yr-debug.java:390-416` 按 `ClipData` 的原 item index 顺序读取 `getUri()`，不会反转
或自行按文件名排序。

`bgj.java:200-225`：

- `ContentResolver.openInputStream(uri)`；
- 写入 cache temp file；
- `fag.z(..., 104857600L)` 限制最多 100 MiB；
- MIME 从 resolver 读取，缺失时回退 `image/*`；
- `vuh.b()` 返回规范化后的尺寸/MIME；
- temp 文件名、最终长度和规范化尺寸进入 IMAGE asset metadata。

超限路径在 `bgj.java:232-247` 记录 `file.max_bytes=104857600` 并删除临时文件。

## 5. 解码、EXIF 与 3000px 规范化

`vuh.java:44-70` 先以 `BitmapFactory.inJustDecodeBounds` 读宽高，必要时从 EXIF ImageWidth/ImageLength
回退；尺寸仍无效时记录 `Failed to decode image dimensions`、删除文件并返回 null。

`w34.java:978-991` 的 orientation 映射为：

| EXIF | rotation |
|---|---:|
| 3/4 | 180 |
| 5/8 | 270 |
| 6/7 | 90 |
| 其他/缺失 | 0 |

`vuh.java:64-70` 对 90/270 度交换对外宽高；当 oriented 宽高均不超过 3000 时直接保留原文件。

`vuh.java:72-137` 对超过边界的输入执行：

1. `3000.0f / max(encodedWidth, encodedHeight)` 计算目标；
2. 选择 `inSampleSize` 后实际 decode；
3. `Bitmap.createScaledBitmap`；
4. 有 EXIF rotation 时 `Matrix.postRotate()` 并创建旋转 bitmap；
5. 以 `Bitmap.CompressFormat.WEBP_LOSSY, 85` 覆盖临时文件；
6. 返回新尺寸和 `image/webp`。

这证明“超过 3000px 直接拒绝”只是 Phase 280 的安全中间边界，不是原版完整入口行为。未来 Harmony
adapter 必须同时完成缩放、方向应用、重编码、MIME/长度更新和失败清理，不能只改 metadata。

## 6. Phase 280 的可证明闭环

Phase 280 只接受已经规范化且能由 ImageKit 完整 decode 的稳定字节，随后完成：

```text
SHA-512 canonical AssetHash
→ pending fsync + atomic rename
→ IMAGE CREATE_BLOCK + outbound operation
→ note_asset LOCAL
→ page revision/snapshot/search + durable history
→ one SQLite commit
→ post-commit availability publish
```

专项 Replay 用 SQLite failure injection 覆盖 reducer/asset/history 回滚、已有 final 文件复用、私有旧路径
同内容/缺失/冲突和外部可读路径拒绝。它不能代替 ImageKit 设备解码、真实 filesystem crash、相册权限、
renderer EXIF 或端到端 UI 验收。
