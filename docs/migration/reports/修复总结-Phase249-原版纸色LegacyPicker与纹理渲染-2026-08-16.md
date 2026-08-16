# Phase 249 修复总结：原版纸色、Legacy Picker 与纹理渲染

## 本阶段目标

承接 Phase 248 明确留下的缺口：严格依据原版 1.0.3 恢复 paper color/legacy picker、完整 `s3a` 草稿、
15 张原版纸张纹理、主画布与缩略图渲染，并修复纸张 alpha 被错误限制为 opaque 的新发现 bug。

## 原版硬结论

- `s3a` 同时保存 size、orientation、backgroundColor、legacyPaperIndex；模板卡才与 `gq0` 组合为 `l3a`。
- `htd/o1` 证明新选 legacy 会清 custom color，新选 custom color 会清 legacy。
- `iq0/n7j` 的六个固定选项为 White13、Cream1、Yellow2、Black15、Blue7、Tan6。
- `ua5 -> rw1(..., false)` 表明当前自定义 HSV UI 不编辑 alpha，但原版实体/wire 仍保留已有 alpha。
- `m3a` 映射完整 15 张 1024×1024 WebP；`p4a/phh/qzi` 以 X/Y repeat BitmapShader 解码和缓存。
- `j79/m4a` 先画底色，再画纹理，最后画 flair；`u3a` 按纸色/legacy 计算线色，不是固定主题灰。
- 深色 legacy 集合为 `{8,11,12,14,15}`；夜间只反转原本不暗的纸张。

完整证据见 `docs/migration/evidence/original-paper-color-legacy-texture-jadx-resource-2026-08-16.md`。

## 已完成修复

1. `OriginalTemplatePickerDraft` 扩展为完整四字段；size/orientation/color/legacy 全部只暂存，模板卡仍是唯一提交点。
2. 新增 custom/legacy stage：新写入严格互斥，读取历史合法组合保持原值。
3. `applyOriginalTemplatePickerSelection()` 写入草稿颜色/legacy；选中态和 favorite 现在比较完整组合。
4. 新增 `OriginalPaperColor.ets`：六个 picker swatch、15 个资源映射、HSV/RGB、原版 legacy line-color、
   常用自定义色映射、亮度算法和暗纸判断。
5. `PageSettingsPanel` 恢复六个 legacy 选项及原生三 Slider HSV；新编辑颜色 opaque，模板卡预览实时反映
   草稿纸色与线色；仅展开已有自定义色不会改写其 ARGB alpha；中英文和 accessibility 文案补齐。
6. 精确复制 15 张原版 WebP；专项 replay 对每张做 SHA-256，一张也没有重新生成或二次压缩。
7. 新增 `OriginalPaperTextureLoader`，验证 1024×1024，明确 `ImageBitmap/PixelMap` 释放。
8. `PaperRenderer` 以 repeat pattern 绘制 legacy 纹理，并按底色 -> 纹理 -> PDF -> flair 的顺序输出；深色模式
   对非暗纸使用 Canvas `invert(1)`。
9. `NoteCanvasView` 用 page/texture generation 防止快速切页的迟到纹理覆盖；相同 index 可安全复用当前纹理。
10. `ThumbnailRenderer` 同样加载 legacy 纹理，并在每次缩略图 finally 释放，避免无界缓存。
11. `PageBackgroundModel` 移除 `colorA === 255` 的错误校验，完整保留原版 0～255 alpha，同时继续拒绝缺通道颜色。

## 边修边审新增修复

### 选中态漏比较纸色与 legacy

初次扩展草稿后，`isOriginalTemplatePickerSelection()` 仍在没有 BackgroundInfo 参数时提前返回，只比较尺寸、
方向和模板。继续审查时发现这会让颜色草稿已变化的模板卡仍显示“已选”。现统一先比较 packed color 和 legacy，
再按需比较 spacing，并增加 fixture 防回归。

### 旧 replay 固化了过时的“从当前值复制颜色”实现

Phase 247 replay 仍要求 `target.colorR = source.colorR`。Phase 249 已证明原版颜色属于 `s3a` 草稿，因此更新
replay 为完整 draft 断言，避免以后被测试错误地逼回旧实现。

### alpha 校验与 Phase 248 原版结论冲突

`OriginalPaperSettings` 已保留 signed ARGB alpha，但 `PageBackgroundModel` 另一条验证链仍要求 255，可能导致
含透明纸色的原版笔记在解析/导入/打开设置时失败。现已统一为完整 byte alpha。

### 展开 HSV 控件会在用户编辑前丢失 alpha

初版 `activateCustomColor()` 在展开控件时无条件重建 opaque HSV 色，导致已有半透明纸色即使没有拖动 Slider 也
被悄悄改成 alpha 255。现仅在从 legacy／无颜色切换到 custom 时产生新 opaque 色；已有 custom 只展开控件，
其色块和草稿继续显示真实 ARGB，实际拖动后才按原版无 alpha 控件写 opaque。

### 无显式颜色与未知 legacy 的线色回退不应使用主题灰

继续直读 `u3a.a(k3a)` 确认：纸张没有显式颜色时先代入 `m09.e` opaque white，因此默认线色命中原版
`#BBBBBB` 映射；legacy index 越界时记录错误并返回 `iu1.b` opaque black。现已补齐这两个边界及暗色反转
fixture，避免 Harmony 主题 token 改写原版纸张内容颜色。

## Fixture、replay 与构建

- 新增 `OriginalPaperColor.test.ets`；更新 `OriginalTemplatePicker.test.ets`、`PageBackgroundModel.test.ets`、
  `List.test.ets`。
- 新增 `d02-original-paper-color-legacy-texture.mjs`，覆盖原版证据、六色顺序、互斥、HSV 无 alpha、展开控件
  不改写旧 alpha、默认/非法线色回退、15 资源 hash、repeat pattern、暗色反转、主画布 generation 与缩略图释放。
- 专项输出：
  `D02_ORIGINAL_PAPER_COLOR_LEGACY_TEXTURE_REPLAY_OK ... legacy-assets=15|sha256-identical=15|repeat-pattern=1|dark-inversion=1|default-line-fallback=1|custom-open-preserves-alpha=1`
- 全量桌面 replay：`REPLAY_FILES=234 FAILED=0`。
- `git diff --check` 通过。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 1 s 748 ms`。
- clean 后严格串行构建：
  - `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 884 ms`，测试 ArkTS 实际重新编译；
  - `note@default`：`BUILD SUCCESSFUL in 32 s 913 ms`。
- 只有项目既有 exception/deprecated 与未配置签名 warning；无本阶段编译错误。

## 未宣称完成与设备待测

- 未启动设备、模拟器、虚拟机、真机或 Hypium。
- 真机需验证：六个 swatch 顺序与点击手感、HSV 连续预览、仍需点击模板卡才保存、收藏组合、popup 窄屏高度、
  15 张纹理细节/接缝、深色反转、legacy + PDF、快速翻页闪烁、缩略图一致性及内存峰值。
- 模板卡小预览使用 swatch 表示 legacy 选择；主画布和缩略图使用真实 WebP。若设备体验要求，可在不改变提交
  语义的前提下继续升级预览纹理。

## 后续与长期文档约束

- 继续按总纲选择下一项高风险静态缺口，保持边修边补审；Phase 249 不冒充关闭仍需设备数据的 M2-R-03/05/06。
- T-042 APK 版本追踪仍严格留到整个 Goal 最后。完成时必须另写中文 Report，说明建立的追踪文档/工具、
  功能和使用方法，再把用途、入口、阅读顺序、新 APK decompile/diff 流程归纳进 Wiki、技术/API 文档和
  新手入门；新手入门必须指出何时使用及从哪里进入。
