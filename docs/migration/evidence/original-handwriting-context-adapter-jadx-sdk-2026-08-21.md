# 原版手写识别全局偏好、Harmony Locale 与 OCR 能力证据

## 1. 证据范围与来源

本证据仅记录静态读取结果，未启动模拟器、虚拟机、真机或 Hypium。原版来源是：

```text
C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage
```

Harmony SDK 来源是本机 DevEco Studio bundled SDK：

```text
C:\Program Files\Huawei\DevEco Studio\sdk\default
```

读取文件 SHA-256：

| 文件 | SHA-256 |
|---|---|
| `kc5.java` | `6C925C4479BFFEC7AA63E38167F31D7EE84CF06049A80F27674D5953C296FC42` |
| `xr.java` | `0EB15420675CF64EC233DEC92D045E2475E3FCF99FBE7FC8CE1586C0FC1BD508` |
| `tc.java` | `8650967C0CFC023E6225189828D46D41CF11F96D5C57909BDC59CBD303B30296` |
| `wb5.java` | `8E0DDE35CDF1A6CE0AA196DDCB348B7DCB701CEA24D7CA62035BF93E7330C544` |
| `xd2.java` | `13FEEFAB484EC4082F1B1C8EB09163BE1F03B21EBC3A704A3816DC2C61838FBF` |
| `vnh.java` | `A9DC414EA17AC1B39CCD85A370280381CB699BE09AB362B6C7FFFE869867BE50` |
| `fr2.java` | `475B1A29C71087E301177A4892A805E0B6C71BC37432E66733568495C7F8096D` |
| `@ohos.data.preferences.d.ts` | `ECF87866737F825A33397D08E0DEDCBE7681F74D5CC5334301BD124A302FDD32` |
| `@ohos.i18n.d.ts` | `39434D03217E7504AC485FE8527663B3791941C4127EAEAC43F3F6F2F033F48C` |
| `@kit.LocalizationKit.d.ts` | `033815E17D5407B7C2C03E85C801120A4696DDDC9EC56798EA31375FE33ABB60` |
| `@hms.ai.ocr.textRecognition.d.ts` | `4505242C5D3DF76A0A93176A0EB4A4AEA6454E4D2D359A500A48D0D275E2973C` |
| `zh-cn_topic_0000002443438060.html` | `E9B5DF5B923771AEFB1A0C814513F7E2157C9625E80772A3CAC064897BAAF7EA` |
| `zh-cn_topic_0000002336126650.html` | `64DD51D97FC1E64554D5E66058C9FC9DDC4084889176E787B547B3770B590908` |

## 2. 原版全局 preference 链路

### 2.1 store/key 与读取类型

`kc5.java:4-10` 声明了独立 DataStore 的字段编码：

```java
public final class kc5 extends hq8 {
    public static final eua g = new eua("recognitionLanguageId");
    public final Object c(gua guaVar) {
        return (String) guaVar.b(g);
    }
}
```

`xr.java` 的 provider 构造分支（JADX case 12）为：

```java
return new kc5(context14, "handwritingRecognitionSettings", new x97(13));
```

因此 global preference 不是 `noteEditorSettings`，而是独立的
`handwritingRecognitionSettings/recognitionLanguageId`。

### 2.2 保存值是 `dc5.I`，不是 canonical tag `dc5.J`

原始 `fr2.java` 的 `invokeSuspend` 主体因 JADX RegionMaker 溢出被省略。为避免仅凭损坏的结构化输出推断，使用同一 APK 的 JADX 单类 debug extraction（命令：
`jadx --single-class defpackage.fr2 --comments-level debug --show-bad-code`）保留关键指令：

```text
fr2 JADX debug extraction: dc5.I
...
tc.init(dc5.I, 1)
kc5.d(tc, continuation)
```

这段 bytecode 对应 `fr2 case 11`：取 `wb5.L` 的 `kc5`，取 `fr2.L` 的 `dc5`，读取 `dc5.I`，构造 `tc` 的 case 8 并异步写入。`tc.java:91-96` 的 case 8 为：

```java
tk8 tk8Var = (tk8) obj;
eua euaVar = kc5.g;
tk8Var.g(euaVar, str);
return mofVar;
```

`dc5.I` 是完整 locale code（例如 `zh_TW`），`dc5.J` 仅是 lookup/display 用 canonical tag（例如
`zh-Hant`）。Harmony preference store 因此在写入前 canonicalize 到 locale code，读取时只接受 23 组 exact
locale/tag，并返回 locale code。

### 2.3 Harmony Preferences 的同实例与补偿边界

`@ohos.data.preferences.d.ts:944-969` 明确同一个 preference 文件在内存中只匹配一个
`Preferences` 实例；`putSync()` 只修改内存对象（约 1479 行），`flush()` 才将修改持久化（约 1732 行）。
因此 Phase 278 的 storage 在对象生命周期内缓存同一个 `getPreferences()` Promise，读取、写入、删除和
flush 都经同一实例；若首次获取被拒绝则清空 Promise，允许后续重试。

事务将 `put()` 与 `flush()` 都纳入 commit catch。这样即使平台在内存 mutation 阶段抛错、又无法保证完全
未改动，也会尝试恢复旧值或删除新键；只有补偿 mutation 成功才再次 flush，补偿 mutation 失败时不把未知
内存状态持久化。commit 与 rollback 都失败时向上报告双错误，不伪装保存成功。

## 3. Harmony LocalizationKit 证据

`@kit.LocalizationKit.d.ts:19-23` 导出 `i18n`；`@ohos.i18n.d.ts:292-301` 声明：

```ts
static getSystemLanguage(): string;
```

`@ohos.i18n.d.ts:343-353` 声明：

```ts
static getSystemLocale(): string;
```

同一 DevEco 离线 API Reference 页面
`JsEtsAPIReference/zh-cn_topic_0000002443438060.html:440-466,501-527` 给出实际格式示例：
`getSystemLanguage()` 在简体中文系统返回 `zh-Hans`，`getSystemLocale()` 在简体中文/中国区域返回
`zh-Hans-CN`。因此适配器解析 BCP-47 连字符形式，同时允许 language API 自带 script/region 与 locale API
互补；Android 风格下划线值、language/locale 语言不一致和平台异常仍 fail closed。

Phase 278 适配层只读取这两个 API，然后把 BCP-47 locale 的 language/script/region 转成已有纯 policy
的 `OriginalLocaleLanguage`。空值、下划线 Android 风格值、未知 variant/extension/private-use 子标签、字段冲突或平台异常均输出空字段，使既有
policy 回退到下一个来源/英文，不猜测邻近地区。

## 4. CoreVision OCR 不等价于原版手写 provider

DevEco 离线 API Reference
`JsEtsAPIReference/zh-cn_topic_0000002336126650.html:5,47,392-937` 明确：通用文字识别面向票据、卡证、
表格、报刊、书籍等印刷品；输入目前只支持颜色格式为 RGBA_8888 的 `PixelMap`；API 提供
`recognizeText()` 与 `getSupportedLanguages()`。该 HTML 的 SHA-256 已在上表固定为
`64DD51D97FC1E64554D5E66058C9FC9DDC4084889176E787B547B3770B590908`。

`@hms.ai.ocr.textRecognition.d.ts:17-25` 标注 syscap：

```text
SystemCapability.AI.OCR.TextRecognition
```

`VisionInfo` 仅接受 `image.PixelMap`；`recognizeText` 返回图片文字
块结果（`@hms.ai.ocr.textRecognition.d.ts:182-205`），配置只有方向检测字段
`isDirectionDetectionSupported`（约 19-35 行）。该接口没有：

- 每条 Ink 独立 pointer down/move/up 生命周期；
- sample force/pressure；
- 调用级 `dc5.I`/locale code 锁定；
- 原版 23 组 MyScript locale 覆盖。

SDK 还提供 `getSupportedLanguages()`（约 220-227 行）、`init()`（238-243 行）和 `release()`（245-250 行），
但“可查询语言”不改变识别调用无法锁定原版 locale、且输入是图片而非笔迹的事实。Phase 278 只增加纯
capability policy，允许上层注入 `canIUse(SystemCapability.AI.OCR.TextRecognition)` 结果作记录；不把 CoreVision
实现成 `OriginalHandwritingRecognitionProvider`，不开放 SelectionOverlay “转文字”入口。

## 5. 对应正式仓实现与验证入口

```text
note/src/main/ets/data/OriginalHandwritingLanguagePreferenceStore.ets
note/src/main/ets/core/adaptation/OriginalHandwritingLocaleAdapter.ets
note/src/main/ets/core/adaptation/OriginalHandwritingRecognitionContextAdapter.ets
note/src/main/ets/core/adaptation/OriginalHandwritingProviderCapabilityPolicy.ets
note/src/test/OriginalHandwritingLocaleAdapter.test.ets
docs/migration/replays/d02-original-handwriting-context-adapter.mjs
```

专项 Replay 必须固定原版/SDK/离线 HTML hash、`dc5.I` 保存值、独立 store/key、同一 Preferences 实例、
put/flush 补偿、Locale 异常 fail-closed、metadata note register → global preference → Harmony Locale 链路，
以及 CoreVision capability 不能满足 stroke-native provider 契约。
