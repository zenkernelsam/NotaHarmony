# 原版 Ink Partial Erase JADX 证据（Notability 1.0.3）

## 结论

原版普通 Ink、Pencil、Dash/Dots、显式 custom path 与 fill path 都进入同一条
`jt1 → n8j.e → o8j.a → u5j.g` 路径。擦除在 Ink 局部坐标分别裁 center/custom/fill，Pencil 使用
`2.84 × baseWidth` 的 attributed outline，并在每个裁切边界推进随机 seed/reference；Dash/Dots 则推进
phase。每个可见 component 最终成为新的 CREATE_INK，源 Ink 随后删除；几何或 style 供应失败必须保持
Unchanged。

## 1. jt1 分别读取 center/custom/fill，并把 eraser 逆变换到 Ink 局部坐标

恢复的 `nota-jt1-showbad-20260815.java:395-454` 显示普通 Ink 分支：

1. `s06.S()` 是 attributed center path；
2. `s06.U()` 非空时经 `jy0.d()` 形成显式 custom path，否则传 `null`；
3. `s06.W()` 非空时形成 fill candidate；`s06.V() != null` 单独作为 fill-color presence；
4. `new dz3(tool, style, width, center, custom, fill, hasFillColor, ...)` 把三条几何交给 `n8j.e()`；
5. `n8j.d(..., s06.P(null))` 用 Ink transform 把擦除 path 转到局部坐标；
6. `n8j.e()` 非空结果交给 `o8j.a()` 物化。

`n8j.java:588-607` 再次确认：`dz3.c` 是 center，`dz3.d` 是显式 custom；custom 缺席时才调用
`pxh.d(center, outlineWidth)` 生成 outline；`dz3.e` 只有在 `dz3.f`（fill color 存在）时才参与裁切。
center clipping 没有加半个笔宽，笔宽只用于单独生成 custom outline。

## 2. Pencil outline 与 style supplier

`o1.java:132-143` 的 `pencilEraseSupport` 只对 Pencil 返回 `jea`：

- outline width 是 `baseWidth * 2.84`；
- style supplier 是 `new ft1(centerComponents, baseWidth, styleMap)`，推进 splat 时使用基础笔宽，而不是
  `2.84` outline 宽度。

`ft1.java:31-68` 对每个裁切位置读取原 component 的 `yyd` seed/reference。位置不在 component 起点时，
它先取从起点到该位置的 center prefix，再用 `new cfa(prefix, baseWidth, seed, reference)` 执行和正式 Pencil
渲染相同的 walk；输出 `cfa.g` 最终 seed 与 `cfa.f` 最后 emitted splat reference。

`cfa.java:166-287` 证明：

- 初始 signed seed 取绝对值；
- 每个 splat 使用同一 LCG `1118393071 / 1946926193`；
- `this.g` 保存 walk 后 seed；
- 只有实际输出 splat 时，`this.f` 才保存最后一个 splat 坐标。

`o8j.java:145-157` 把 `vyd(seed, reference)` 写回新的 `yyd`，Dash 两字段明确置零。因此 Harmony remnant
必须从裁切起点重新生成稳定 Pencil style-map，并让重新载入后的 splats 与第一次物化完全一致。

## 3. Dash/Dots phase 在裁切点推进

`n8j.java:608-633` 在没有专用 Pencil supplier 时，为 DASH/DOTS 构造 `ft1(styleMap, center,
dashPeriod)`：DASH period 为 `3 × width`，DOTS period 为 `2.001 × width`。

`ft1.java:70-91` 计算“源 phase + 从原 component 起点到裁切位置的中心线距离”，再对 period 做正模。
`o8j.java:160-164` 把结果 `uyd` 物化为新的 `yyd`：Pencil seed/reference 置零，phase 使用推进值，period
只保留原 style entry 的 period。全零 `yyd` 会在 `o8j.java:188-201` 被省略。

## 4. center/custom/fill component 与 fill-only remnant

`n8j.java:772-877` 的 `zz3` 组装顺序为：

- `zz3.a`：当前 custom component 内的 retained center fragments；
- `zz3.b`：clipped custom component；
- `zz3.c`：与它相交的 clipped fill components；
- 剩余 fill component 额外生成 `zz3(empty, empty, fill)`。

`o8j.java:61-111,297` 按相同顺序将三条 path 交给 `u5j.g()`。因此 fill-only component 也是合法的
CREATE_INK，不能因为没有中心线或 custom outline 就丢弃；再次 partial erase 时也必须继续可裁切。

## 5. AudioLinked 区间与失败语义

`o8j.java:212-285` 使用 retained center component 在源 center 总长度中的最小/最大距离，重算 AudioLinked
开始偏移与 duration；没有 center 的 fill-only component保留完整区间。

恢复的 `jt1` 对 `n8j.d/e` 任一 `null` 都不加入删除/替换集合；`n8j.e()` 空列表才表示完整删除。因此：

- `null`：Unchanged；
- 空列表：删除源、不建 remnant；
- 非空列表：CREATE_INK remnants 后删除源。

Harmony 不能把奇异 transform、PathOp、path conversion、style supplier 或 materialization 失败降级成删除。

## 文件哈希（SHA-256）

- `n8j.java`：`7E6CCE408B58F34715CD01CE196B6D347F5EC949E110129E9934F5EE46EDC726`
- `o8j.java`：`57FF958651A2A064B48946360AC6C3EF8B8C3828D56D0FE198AA84486AB69666`
- `o1.java`：`C2F8B4186C6697CDE59304A34D8E3AF1F74370248F4DBF08D3D38479A49BB7D1`
- `ft1.java`：`7313362583E48249CB52B86B3FCA9B2941D0AC56DEABB557BDCDFBE7AD024474`
- `cfa.java`：`3DC68B78717C22A7EE02F11FB3614B8C205CCCF3859FF4F9BF42D75C741856F9`
- `dz3.java`：`15DC6F6DAF8DA9CB11FA3378FD0554AC78CD15A82F6A2A85595037ADC9A47A26`
- `zz3.java`：`F36D9F9C09626C4BA0523F09929542B70F02668600F7D4E765C82268C61F78F3`
- 恢复的 `jt1`：`2E1750C94B811A22F61E0DB5CC2F57A7BC9C5B132B2B22F734902DE3105A6FFC`
