# Phase 1431 证据：assets/ 尾部轴收口裁决

日期：2026-08-09
关联：ADR-1366；fixture `docs/migration/replays/d02-original-assets-tail-sweep.mjs`（6 项）。

## 范围

`decompiled_1.4.2/resources/assets/` 全量 576 文件与 Harmony
`rawfile/`（488）diff 后的残余簇。

## 一、spellcheck/en_words.dat：DebugOnly 门禁 → fail-closed

词典管线：

- `bc1.a(List<String>)`：GZIP 解 `spellcheck/en_words.dat` → ~150k
  HashSet（`rs.java:545`）；`v6n.h(str, dict, BreakIterator)`
  分词提取 misspell 区段（≥3 字母、连字符邻接跳过、's 词尾处理）。
- `fal.b` 按文本缓存去重；`cji`（`wki.D` 文本清单 → `fal.b`）
  产出 `rii{l74 文本, xhc 区段表}`；`ff7:448-490` 把 misspell
  区段并入 `zle` 文本布局 → 编辑器波浪下划线。

门控证据：

- `h35.java:390`：`NOTE_SPELLCHECK`（序号 74）构造参数 `qd5`；
  `qd5.toString()` = `"DebugOnly"`。
- `h45.b()` 分支：`qd5` 仅在 `a().compareTo(oe5.F) <= 0`
  （调试/内部构建档）返真，生产构建恒 false。
- `wki.java:175`：`this.C0 = h45.b(h35.a1)`；`D0/E0` 两个
  derived flow 都以 `zB`（flag）与 `j8b.v`（用户偏好）合成
  可见性 —— flag=false 时管线输出不可达。
- `axg.java:115`：设置行 `check_spelling`/`check_spelling_description`
  由 `!h45.b(h35.a1) ? em4.F : [...]` 门控 —— 生产连设置项都不渲染。

裁决：1.4.2 未发布的调试特性（与 STICKERS `rd5` InternalUserOnly
先例并列的更严门）。词典资产与 misspell 管线不移植，fail-closed。

## 二、vendored / 平台边界资产

| 资产 | 属主 | 裁决 |
|------|------|------|
| `conf/{diagram,en_US,math2,raw-content2,shape}.conf` + `resources/{analyzer,document_layout,en_US,math,shape}/*.res` | MyScript iink 引擎配置/资源 | 随 ADR-0645 后端/引擎边界 fail-closed |
| `mlkit-google-ocr-models/`（21 个 .tflite/.binarypb/.bincfg） | Google MLKit 文档扫描/识别模型 | vendored GMS，无 Harmony 宿主 |
| `dexopt/baseline.prof(m)` | ART baseline profile | Android 平台构件，无对应概念 |
| `ConversionRates.csv` | `k4f` 付费墙币种换算 | 订阅后端边界 |
| `PublicSuffixDatabase.list` | OkHttp public-suffix 表 | vendored HTTP 栈 |
| `brushpacks/` | Google Ink 效果包 | ADR-1360 已裁决 fail-closed |
| `glmath/`（73） | MicroTeX 字体/映射 | 已打包 `rawfile/glmath`（数学渲染链） |
| `covers/`、`papertemplates/`、`planners/`、`emojis_unicode.json` | 一版资产 | 均已移植 |

## 结论

`assets/` 轴全域收口：一版资产或已移植，或落在
未发布（DebugOnly/InternalUserOnly）/ vendored / 后端 /
平台边界四类 fail-closed 之一，无新增缺口。
