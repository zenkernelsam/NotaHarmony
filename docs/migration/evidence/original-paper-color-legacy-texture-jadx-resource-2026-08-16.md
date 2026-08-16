# 原版 1.0.3 纸色、legacy picker 与纸张纹理证据

## 范围

- 原版：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- 目标工程：`C:\HarmonyProject\NotaHarmony`
- 结论用途：Phase 249，恢复 `s3a` 完整 picker 草稿、六个 legacy 选项、自定义 HSV、15 张纸张纹理、
  原版线色与深色反转策略。

## 1. `s3a` 是四字段草稿，模板卡才把它与线型组合

`sources/defpackage/s3a.java:5-8,55` 明确列出：

```text
paperSize
paperOrientation
backgroundColor
legacyPaperIndex
```

`l3a.java:43-72` 再把 `s3a` 与 `gq0` 的 line type/spacing 组合成最终 `k3a/nz9`。因此颜色和 legacy
与尺寸、方向一样属于 picker 草稿，不应在点 swatch/拖 HSV 时直接保存默认模板或当前笔记；`rge/vge`
仍以模板卡回调作为最终 `l3a` 提交边界。

## 2. 新选择互斥，但历史合法值不能在读取时被擅自清洗

两个入口证据相同：

- `htd.java:77-99`（`vge`）
- `o1.java:220-242`（`rge`）

选择 legacy 时调用：

```java
s3a.a(current, null, null, null, legacy, 3)
```

即写 `legacyPaperIndex` 并把 `backgroundColor` 置空。选择自定义色时调用：

```java
s3a.a(current, null, null, Integer.valueOf(tu1.b(color)), null, 3)
```

即写 packed ARGB 并把 legacy 置空。`s3a` 本身没有禁止旧数据同时带两个字段，故 Harmony 读取/导入保留
完整合法状态；只有当前 UI 新动作执行互斥。

## 3. 六个 legacy picker 选项及 UI swatch

`iq0.java:19-29` 给出固定顺序和 legacy index；`n7j.java:102-116` 给出 UI 色值：

| 顺序 | 名称 | index | swatch |
|---:|---|---:|---|
| 1 | White | 13 | `#FFFFFFFF` |
| 2 | Cream | 1 | `#FFFBF8F4` |
| 3 | Yellow | 2 | `#FFFCF6CF` |
| 4 | Black | 15 | `#FF292929` |
| 5 | Blue | 7 | `#FFE1E8EC` |
| 6 | Tan | 6 | `#FFE7DDB4` |

这些只是 picker 识别色，不是用纯色代替原纹理的许可证。

## 4. 自定义色是 HSV，当前 UI 不编辑 alpha

`ua5.java:259-274` 把已有 RGB 转为 HSV，并调用：

```java
rw1.c(..., ru1Var, false, ...)
```

末尾 `false` 关闭 alpha 编辑。因此：

- 读取、Room、FlatBuffer 和已有笔记必须保留完整 signed ARGB alpha；
- 仅打开/展开 HSV 控件不能视为编辑，必须继续保留已有 alpha；
- 用户实际拖动 HSV，或从 legacy／无颜色切换成自定义色后，产生的新颜色为 opaque；
- 不能再次在 `PageBackgroundModel` 用 `colorA === 255` 拒绝历史数据。

## 5. 原版有 15 张真实 1024×1024 WebP，不是近似纯色

`m3a.java:9` 将 index 1～15 一一映射到：

```text
core_paper__paper01.webp ... core_paper__paper15.webp
```

资源位于 `resources/res/drawable/`，全部为 1024×1024 纸张纹理。Harmony 侧逐字节复制到
`note/src/main/resources/rawfile/`，SHA-256 与原版一致：

| 资源 | SHA-256 |
|---|---|
| paper01 | `4371173D7542DA7563439176CBDADCDAFEDAF4A6D63F8C7676D1C9C08EF75E13` |
| paper02 | `774F9427AEC7E8A37CE85F964BF616484ED347DB94C3F1866A872FA5736DE140` |
| paper03 | `D810C8F1E6FF97EBBB76298EFB0B3E89DED3A339DDF9F1F0234F8171AB325BBC` |
| paper04 | `C90C40AE148AC0534A5CD2599917022449F7B0F80A260314BAD241BAA9C8FE47` |
| paper05 | `F8C1CC7FEA65DF47EBC274B39BD3CB3FFC8C20246A90944638346896E34F000B` |
| paper06 | `15AAF0A6E4B8C9B996D2504ACF9AC2F05311BF4A00AB30BD22A4BED5C7E95F1B` |
| paper07 | `31193623888063C2FE067DFD647597BE37AFD54F8E4071EB8EF707A34A62B53A` |
| paper08 | `D4D6B5D1EE30107EE5AE1B6B71160B277858A418930E7F1C834B9F4F7DA4CEF5` |
| paper09 | `5F5681420CCA3AD54B390201EBA9A71E3E36A194F68D71ECB51A652249A18791` |
| paper10 | `E4EA1C84E384D6602BC4E122D05BCC0C079F1905B6DEF6BB53059EF6677C7C59` |
| paper11 | `958E2C986A09E3A4184C4A5A7C68A581682B85F7461A5D303C3DECBF478E8205` |
| paper12 | `2146A43B0EE4219A37C6FB7DB8DDB79F852C47225E315C68C4A65F8F46F0148B` |
| paper13 | `3B647C28DC79DDDF7AA1D778DFE06B1595A594889A629666FB50DC9F1FD31475` |
| paper14 | `B4A508DF2F2658B16E5D3B35896E720EE3C6FD32FA17989ECD02136EA2DCDBF4` |
| paper15 | `1940ED07937FF0F92E923B2F0C02E553A06DA2FCB105FBC386A599D8F83F93D7` |

## 6. 纹理横纵 repeat、缓存；无映射时不伪造

对原版 DEX 生成的 simple JADX：

- `.codex-tmp-phase249-jadx/p4a-simple.java:362-370`：从 `m3a.a` 查资源；无映射只记录
  `Invalid legacy paper index`；
- `:373-401`：先查 `ConcurrentHashMap`，再 `BitmapFactory.decodeResource`、创建 `BitmapShader`，最后
  `putIfAbsent`；
- `phh.java:105-106` 把两个 tile-mode 参数传入 `qzi.d()`；
- `qzi.java:87-97` 证明参数 `1` 是 `Shader.TileMode.REPEAT`，所以 X/Y 均 repeat。

Harmony 不能为 wire 中未知的 index 生成近似资源；当前 loader 对 1～15 精确解码，其他值安全回退到底色并记录
不可用。

## 7. 绘制顺序与深色策略

`m4a.java:45` 的 `PaperTileInfo` 顺序为 backgroundColor、backgroundBrush、brushColorFilter、paperStrokes。
`j79.java:179-214` 实际依次绘制：

1. background color；
2. legacy background brush；
3. flair lines/grid/dots。

Harmony 保持纸张层的同一顺序，并把 PDF 放在纸张底层与 flair 之间，以延续已有 `paper + PDF + flair`
组合语义。

`m3a.java:10` 定义深色 legacy 集合 `{8, 11, 12, 14, 15}`。`p4a` 只在夜间模式且纸张本身不暗时反转
背景、纹理和线色；已有暗纸不重复反转。Harmony 使用 ArkUI Canvas 自 API 11 支持的 `filter = invert(1)`
对 repeat pattern 应用等价过滤，底色和线色用相同 RGB 反转规则。

## 8. 原版线色不是固定主题灰

`u3a.java` 对 legacy index 使用固定 line-color 表，对自定义色先查原版常用颜色映射，再按背景 HSV/亮度计算
对比线色。六个 picker legacy 对应：

| index | line color |
|---:|---|
| 13 | `#FFA3B7D3` |
| 1 | `#FFC2C0B7` |
| 2 | `#FF948E79` |
| 15 | `#FF5A5A5A` |
| 7 | `#FF6E97BD` |
| 6 | `#FF948E79` |

因此 `PaperRenderer` 不能继续无条件使用 `theme.paperLineColor`。

`u3a.a(k3a)` 还有两个必须保留的边界：没有显式背景色时先代入 `m09.e` opaque white，因此线色命中
`#FFBBBBBB`；legacy index 没有表项时记录错误并返回 `iu1.b` opaque black，而不是 Harmony 主题灰。

## 验证与剩余运行态项目

- 专项 replay：`D02_ORIGINAL_PAPER_COLOR_LEGACY_TEXTURE_REPLAY_OK`
- 全量 replay：`REPLAY_FILES=234 FAILED=0`
- 15/15 资源 SHA-256 与原版相同
- clean 后 `note@ohosTest`、`note@default` 均通过严格 ArkTS 编译
- 未启动设备、模拟器、虚拟机、真机或 Hypium

设备仍需确认：Canvas filter 是否对 pattern fill 与主流设备 GPU 一致、popup 窄屏高度、WebP 解码内存、
页面快速切换时无闪烁、缩略图与主画布像素接近、legacy + PDF 的真实原版组合顺序。
