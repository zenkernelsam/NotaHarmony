# Phase 817 — 1.0.1→1.0.3 资源/manifest 全量差(三版谱系补全)

## 目的

Phase 797 登记了 1.0.1→1.0.3 的 strings 层差异(账户删除加固 +
付费墙重组)。本阶段把 1.0.x 行内差扩展到资源树与 manifest
全量 —— 三版谱系的资源层证据补全。

## 取证路径

- `decompiled_1.0.1/resources/` vs `decompiled_1.0.3/resources/`
  全树 SHA-256(1,166 → 1,174 文件)
- manifest `android:name` 集合差

## 文件级差异

**移除 11** —— 全部 `META-INF/services/*` 混淆名(service-loader
注册重排，无语义)。

**新增 19**:

| 项 | 性质 |
|---|---|
| `META-INF/Singular-v12.15.0-…kotlin_module` | **Singular 归因 SDK 在 1.0.3 首次随包** |
| `META-INF/services/*` ×11 | 混淆名重排(对应移除侧) |
| `play-services-appset.properties` | Play AppSet(隐私合规设备标识) |
| `res/font/gtamericamono_bold.otf` | **品牌字体:GT America Mono Bold** |
| `res/font/gtflairebasic_extra.otf` | **GT Flaire Extra** |
| `res/font/proximasoft_medium.otf` | **Proxima Soft Medium** |
| `res/font/untitledserif_{medium,regular_italic}.otf` | **Untitled Serif ×2** |
| `res/drawable/ui_designsystem__general_check_tny_bold.xml` | 小尺寸加粗对勾图标 |

即 1.0.1→1.0.3 补齐了 5 个品牌字重(品牌字体家族在 1.0.3
补全,与 Phase 803 的字体目录面衔接)。

**内容变化 9**:`AndroidManifest.xml`(见下)、`version-control-info`、
`dexopt/baseline.prof{,m}`(重编译)、`plurals/strings/public`
(键增删见下)、`core_remoteconfig` 默认值、`ads-identifier` props。

## strings/plurals 键差

- strings 1482→1503(+33/−12):新增 `app__account_deletion_notice_*`、
  `feature_settings__account_deletion_{confirm,error,in_progress,
  sync_failed}_*` 账户删除全生命周期族 + `feature_settings__logout_
  {sync_now,syncing,synced,sync_failed,unsynced}` 与
  `sign_out_countdown` 登出同步状态族;付费墙键组重组
  (plan_name_starter、discount footnote、period 名词/副词化)。
  与 Phase 797 的"账户加固+付费墙重组"结论一致且更完整。
- plurals 15→16:新增 `feature_paywall__free_trial_footnote`。

## manifest 差异

- `FileProvider` → `ExportFileProvider`(自定义导出 Provider)。
- 新增 queries:`com.facebook.katana`、`com.instagram.android`
  (FB/IG 安装探测 —— 分享目标可见性)。
- 新增权限:`com.google.android.gms.permission.AD_ID`、
  `com.singular.preinstall.READ_PERMISSION_SINGULAR` ——
  **Singular 归因链路上车**(广告 ID + 预装归因权限)。
- 新增 meta-data:`google_analytics_adid_collection_enabled`。

## 结论

1.0.1→1.0.3 = Singular/Ads 归因栈上车 + 品牌字体补全 +
账户删除/付费墙文案重组(797)+ 导出 Provider 定制 +
FB/IG 分享探测。全部为增量加固与归因接入,无功能面下线。
