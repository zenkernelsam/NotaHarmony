# Phase 222 修复总结：Native Math 字体来源与 ExternalFont 保真

## 发现

Phase 221 完成四字段度量与框内居中后，继续对照原版 `libglmath.so` 的 Font port，确认 Harmony
虽然已经保存 `file_/style_/size_`，但 `_create(name, style, size)` 在入口直接丢弃了 name：

```cpp
return std::make_shared<HarmonyFont>(std::string(), style, size);
```

因此 `\externalfont{...}`、自定义 text font path 以及原版字体来源身份全部失效；Phase 220 修好的
style 传播只能作用在默认字体上。

## 原版依据

- MicroTeX：`externalfont -> TextRenderingBox::setFont(name) -> Font::_create(name, PLAIN, 10)`。
- 原版 native：
  - `Font::create @ 0x2200b8` 和 `Font::_create @ 0x220140` 都复制来源字符串；
  - `deriveFont @ 0x221280` 保留来源与 size；
  - `operator== @ 0x221358` 比较来源、style、size；
  - `getBounds @ 0x220db8` 与 `drawWide @ 0x22074c` 都向 Java 传递 fontFile/style/size。
- `GLMathTextMeasurer` 与 `MathDrawTarget` 使用同一个 `lz4` resolver。
- `lz4` 对非空来源先尝试 `Typeface.createFromFile`，失败按原 style 回退默认字体，并以来源/style 为 cache key。

## 修复

- 将 `Font::_create` 的匿名字符串参数恢复为 `name`。
- 创建 `HarmonyFont` 时原样传入 `name`，复用已有的：
  - 空来源默认 Typeface；
  - 非空来源文件加载；
  - 文件失败默认 Typeface fallback；
  - fake bold 与 italic skew；
  - deriveFont 来源传播；
  - file/style/size equality。
- 新增 `d02-native-math-font-source-identity.mjs`，锁定 externalfont 调用链、原版 Java resolver、
  Harmony 文件尝试/fallback、style 保留、来源传播和身份模型。

## 修改文件

- `note/src/main/cpp/nota_math.cpp`
- `docs/migration/replays/d02-native-math-font-source-identity.mjs`
- `docs/migration/adr/ADR-0199-native-math-font-source-identity.md`
- `docs/migration/reports/修复总结-Phase222-NativeMath字体来源与ExternalFont保真-2026-08-15.md`

## 验证

- 字体来源与 externalfont 专项 replay：`TOTAL=16 FAILED=0`。
- Native Math 字体样式/基线专项 replay：`TOTAL=12 FAILED=0`。
- Native Math 四字段度量/居中专项 replay：`TOTAL=15 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=209 FAILED=0`。
- `note@default assembleHap`：Native Ninja 与 PackageHap 通过，`BUILD SUCCESSFUL in 4 s 279 ms`。
- `note@ohosTest assembleHap`：OhosTest 与 native 构建链通过，`BUILD SUCCESSFUL in 1 s 892 ms`。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 把可访问的 `.ttf/.otf` 路径交给 `\externalfont{...}`，对比加载前后的 text 公式字形、宽度与 baseline。
- 使用不存在的路径，确认稳定回退且 bold/italic 仍生效。
- 交替渲染多个不同字体路径，确认 measure 与 draw 不串用来源。
- 对比 `Serif`、`SansSerif` 与空来源，确认 fallback 稳定；即使字形相同，也不得出现对象身份错乱或崩溃。
