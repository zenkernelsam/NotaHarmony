# ADR-1366：assets/ 尾部轴收口裁决（spellcheck DebugOnly + vendored 族）

- 状态：Accepted
- 关联：ADR-0645（MyScript iink 边界）、ADR-1360（brushpacks）、
  ADR-1364（rd5 InternalUserOnly 先例）、ADR-1363（资源轴收口）、
  evidence `phase-1431-assets-tail.md`、
  fixture `d02-original-assets-tail-sweep.mjs`

## 背景

`resources/assets/`（576 文件）与 `rawfile/` 逐文件 diff 后的残余簇。

## 决定

### spellcheck：fail-closed（DebugOnly 未发布）

- `bc1`/`v6n.h`/`fal.b`/`cji`/`ff7` 词典标注链完整存在于代码中，但
  `NOTE_SPELLCHECK`（`h35.a1`）以 `qd5`（`toString`="DebugOnly"）
  构造；`h45.b()` 仅在调试/内部构建返真（`a().compareTo(oe5.F)<=0`）。
- `wki.C0` 生产恒 false → `D0/E0` 合成可见流断开；
  `axg.java:115` 设置行同样被 `!h45.b(a1)` 短路。
- `spellcheck/en_words.dat` 不打包；不虚构设置行与下划线渲染。

### vendored / 平台边界

- `conf/diagram.conf` 等 5 个 iink conf + `resources/**/*.res` →
  MyScript iink（ADR-0645）。
- `mlkit-google-ocr-models/` → vendored GMS 模型。
- `dexopt/baseline.prof(m)` → ART 平台构件。
- `ConversionRates.csv` → `k4f` 付费墙后端。
- `PublicSuffixDatabase.list` → vendored OkHttp。
- `brushpacks/` → ADR-1360 已裁决。

### 已移植确认

- `glmath/`（MicroTeX）、`covers/`、`papertemplates/`、`planners/`、
  `emojis_unicode.json`（Phase 1430）均在 `rawfile/`。

## 后果

`assets/` 轴全域收口：无新增移植缺口，残余全部四类 fail-closed
（未发布 / vendored / 后端 / 平台）。
