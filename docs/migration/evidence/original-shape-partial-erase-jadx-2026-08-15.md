# 原版 Shape Partial Erase JADX 证据（Notability 1.0.3）

## 结论

原版不是把 Shape 采样成折线后再走普通 Ink 中心线橡皮。它先恢复 Shape 的原生 Android
`Path`，把擦除路径逆变换到 Shape 局部坐标，分别裁切 center/custom/fill 三种几何，最后把每个可见
component 物化为新的 CREATE_INK，并删除原 Shape。

## 1. Shape center path 是原生曲线

- `q16.java:531-545`：`q16.e(m4d)` 优先读取缓存的 Android `Path`，缓存缺席时调用
  `xai.d(((n5d) shape).S())`，不会读取渲染层采样折线。
- `xai.java:125-145`：LINE 明确使用：
  - 无控制点：`moveTo + lineTo`；
  - 一个控制点：`moveTo + quadTo`；
  - 两个控制点：`moveTo + cubicTo`。
- `xai.java:147-152`：ELLIPSE 使用 Android `Path.addOval(0, 0, width, height, CW)`。
- `xai.java:158-178`：POLYGON 使用逐点 `lineTo`，至少三个点时 `close()`。

因此 Harmony Shape 局部擦除必须让 Path boolean、center clipping 和 CREATE_INK path 尽可能保留曲线
verb；采样折线只能用于 hit-test 或 PathIterator 不提供权重的 conic 最终序列化兼容近似，不能作为主几何
来源。该限制同时适用于 center/custom/fill，绝不能把 conic 控制点按 weight=1 quadratic 编码。

## 2. 箭头不裁短擦除用 center path

- `o1.java:123-131` 的 `shapeErasePaths`：
  1. `pathE = q16.e(shape)`；
  2. Pair 第一项直接是 `sh8.x(pathE)`，即完整 center path；
  3. `l96.W(definition, pathE, borderWidth)` 只取 Pair 第二项的 arrowhead path。
- `l96.java:5196-5239`：箭头显示主线可由 `PathMeasure.getSegment(0, bodyLength)` 裁短，但
  `shapeErasePaths` 没有把这个 trimmed path 作为擦除 center path。
- `d1j.java:9-26`：箭头半宽是 `scale(width) * 20`，长度是 `scale(width) * 46`；小于 2 和大于 4
  的宽度使用原版分段压缩公式。

所以 Shape→Ink 的局部擦除不能把 center path 提前截到箭头 base；箭头 triangle 是额外 custom outline
几何，完整主线仍参与 center clipping。

## 3. jt1 把擦除路径逆变换到 Shape 局部坐标

恢复的 `jt1` Shape 分支（`nota-jt1-showbad-20260815.java:470-534`）证明：

1. 读取 `shapeErasePaths` 的完整 center 与 arrowhead；
2. LINE 的 fill candidate 为 `null`，ELLIPSE/POLYGON 的 fill candidate 是 center path；
3. 构造 `dz3(tool, style, borderWidth, center, null, fillCandidate, hasFillColor,
   arrowhead, borderWidth, emptyStyleList, null)`；
4. `n8j.d(..., shape.P(null))` 用 Shape 的矩阵把擦除 path 转到局部坐标；
5. `n8j.e()` 返回零个或多个 retained component；`o8j.a()` 把它们逐个建成新 Ink。

`n8j.java:516-524` 也直接显示 `n8j.d()` 对矩阵做平移修正后调用 `wx0.k(y81)`，没有额外把中心线
擦除半径扩大半个 Shape border width。border width 只用于生成要单独裁切的 custom outline。

## 4. center/custom/fill component 归属

`n8j.java:588-607`：

- `dz3.c` 是 center path；
- 仅在存在 fill color 时，`dz3.e` 才作为 fill path 裁切；
- `dz3.d` 是显式 custom path；Shape 传入 `null` 时，由 `pxh.d(center, borderWidth)` 生成 outline，
  再与 `dz3.g` arrowhead 合并。

`n8j.java:772-875` 的 component 组装顺序是：

- `wx0VarE3`：落在当前可见 outline component 内的 center fragments；
- `wx0VarE`：当前 custom-outline component；
- `wx0VarE2`：与当前 component 相交的 fill components；
- `new zz3(wx0VarE3, wx0VarE, wx0VarE2)`，另为剩余 fill-only component 生成
  `zz3(empty, empty, fill)`。

`o8j.java:61-111,297` 随后把 `zz3.a/.b/.c` 分别转换并按同一顺序交给 `u5j.g()`；
`faj.java:9-16` 与 `ys2.java:475-507` 将这三条 path 写入 CREATE_INK fields 9/10/11，field 12 写
fill color。Harmony production decoder `OriginalCreateInkOperation.ets:103-109` 已独立确认 fields 9/10/11
依次是 center/custom/fill。

因此一个可见 component 的 Harmony remnant 必须保持：

- center fragment → `pathPoints/cubicSegments`；
- clipped outline → `customPath`；
- clipped interior → `fillPath`；
- 只有 fill path 存在时才携带 `fillColor`。

## 5. 失败与完整删除

- `n8j.e()` 返回 `null` 表示裁切失败/无法证明，调用方保持实体不变；不能把失败降级成删除。
- 返回空列表表示 Shape 被完整擦除；调用方删除 source，不创建 remnant。
- 返回非空列表表示先 CREATE_INK remnants，随后 source Shape 进入原版删除事务。

## 文件哈希（SHA-256）

- `xai.java`：`442346ECC33F91E1910E0B80EF72FD6880F8C7ACEF393AE6EE6EA9039F6467E6`
- `q16.java`：`4E9B41CF0EA8FDED3ABAA0944353CE378071D5C50266A5E582D2BBA9460E4DBA`
- `o1.java`：`C2F8B4186C6697CDE59304A34D8E3AF1F74370248F4DBF08D3D38479A49BB7D1`
- `n8j.java`：`7E6CCE408B58F34715CD01CE196B6D347F5EC949E110129E9934F5EE46EDC726`
- `o8j.java`：`57FF958651A2A064B48946360AC6C3EF8B8C3828D56D0FE198AA84486AB69666`
- `l96.java`：`FE118CD08E93845CC7625ED8692162D8B720F00DC6FDDF5FD35844B73F7EF0C4`
- `d1j.java`：`1F2F0FA91E09237BC576B9CF12EF8899473B02B7AB5C043C2A37FE9209271AF2`
- 恢复的 `jt1`：`2E1750C94B811A22F61E0DB5CC2F57A7BC9C5B132B2B22F734902DE3105A6FFC`
- 恢复的 `kt1`：`7998C16F474E3E900455E95E61CDCFC4F37D49764C9EBE95A2B63D001FCD8218`
- 恢复的 `wc` fallback：`17A0E86702415B5A4181F8F2B1E81E147AD23D3B6DA1DEDB3C60B58B97679895`
