# Phase 815 — base APK 内部清单闭合(dex/META-INF/properties)

## 目的

XAPK 拆分面(795)、原生库(811)、签名块(814)之后,base APK
自身的内部结构(dex 计数、META-INF、*.properties、顶层成员)
尚未按版本登记。本阶段完成 base APK 容器层收敛。

## 取证路径

- `Notability_{1.0.1,1.0.3,1.4.2}/com.gingerlabs.notability.apk`
  的成员清单(zip central directory)

## 成员级对比

| 版本 | 总成员 | dex | res | assets | META-INF |
|---|---|---|---|---|---|
| 1.0.1 | 1132 | 3 | 659 | 115 | 175 |
| 1.0.3 | 1140 | 3 | 665 | 115 | 176 |
| 1.4.2 | 1569 | **4** | 625 | 576 | 184 |

- **dex 3→4**(`classes4.dex` 新增):1.4.2 代码量跨过第三个
  64K-method 边界,与 1.4.2 的功能扩容(画廊/Learn/贴纸等已
  登记面)一致。
- res 成员 659→625(厂商裁剪,Phase 791/810 已登记);
  assets 115→576(Phase 761/762/763/792/813 全量登记);
  META-INF 175→184。

## META-INF 差异(−15 / +23)

移除:
- `Singular-v12.15.0` kotlin_module → 升级为 `v12.16.0`
  (Singular 归因 SDK 小版本 bump,Phase 801 邻近面已见)。
- `FastDoubleParser-NOTICE`/`thirdparty-LICENSE` → 重命名为
  `FastDoubleParser-ThirdParty-LICENSE` + `Schubfach-LICENSE`
  (JDK 双精度解析库许可重组)。
- `native-image/okhttp` GraalVM 元数据移除。
- 11 个 `META-INF/services/*` 混淆名服务注册文件替换为 10 个
  新混淆名 —— service-loader 注册混淆名重排(无语义)。

新增:
- `androidx.ink_ink-storage.version` —— 与 Phase 798 依赖增量
  互证。
- 7 个 `dev/zacsweers/metro*` verification.properties ——
  **Metro DI 框架**(Zacsweers Metro)1.4.2 新随包。
  应用代码内无 `import dev.zacsweers` 直接引用(混淆后经由
  生成代码/传递依赖使用);`dev/zacsweers/metrox` 包实体存在
  于 sources。登记为厂商依赖增量。
- `jsoup/LICENSE` —— jsoup 传递依赖(已登记为 dead dep)。
- `androidx.lifecycle/lifecycle-common LICENSE.txt`。

## *.properties 差异

`META-INF/dev/zacsweers/metro*` ×7 为唯一功能性新增,其余
(firebase/play-services/opentelemetry/billing 等 ~60 项)两版一致。

## 顶层杂项(两版一致)

`AndroidManifest.xml`、`DebugProbesKt.bin`、`io/`、`google/`、
`kotlin/`、`{app-update,asset-delivery,billing}{,-ktx}.properties`、
`common/core-common/image.properties` 等 marker 文件两版并存。

## Harmony 侧

Harmony HAP 无 dex/META-INF 概念；容器差异仅为打包结构登记,
无移植动作。Metro DI 为原版内部实现细节，不影响行为面。

## 结论

base APK 容器层闭合:dex 3→4 为唯一结构性增量(代码扩容),
META-INF/properties 差异全部归属已登记集群(Metro/jsoup/
ink-storage/Singular bump/混淆名重排)。
