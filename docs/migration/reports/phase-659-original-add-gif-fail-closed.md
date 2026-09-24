# Phase 659：「Add GIF」Klipy 联网挑选 fail-closed 登记

日期：2026-09-24
接续：Phase 658（多选文件导入）

## 原版依据

- `qc` 插入菜单第 4 序位 `add_gif`，`function4 != null` 才渲染；
  `u49` 中回调 `qb5(gl8Var10,23)` 由 `lc4.a(ac4.k0)` 门控——
  `ac4.k0` = ANIMATED_IMAGES 特性旗标。
- `f65` 构造 `https://api.klipy.com/api/v1/<内嵌客户密钥>/gifs/...`
  （per_page/locale/q 参数），"Powered by Klipy" 归属文案在资源中。
- `p55` = GifItem(previewUrl, fullUrl, w, h)；选中经 `js7`/`re0`
  下载到 `gif_*.gif` 临时文件（100MB 上限）→ `je4` FileInfo →
  `bgj.b` 落 `cz0.IMAGE` 元素（mime=image/gif）。
- 详见 `docs/migration/evidence/original-add-gif-klipy-jadx-2026-09-24.md`。

## 决定（ADR-0626）

- Klipy 为第三方付费 SaaS + 厂商专属密钥，HarmonyOS 无 SDK，
  **结构性 fail-closed**；菜单不渲染 add_gif（等价原版旗标关闭态）。
- 本地 `.gif` 文件经 Add Files（P653/P657/P658）仍导入为 IMAGE
  元素；动画帧表现由渲染层另案评估。

## 验证

- 桌面回放：`d05-original-add-gif-fail-closed.mjs` 16 断言绿
  （原版链路 + Harmony 无 Klipy 表面 + .gif 本地导入保留）；
  全量套件见提交信息。
- HAP：`note@ohosTest` / `note@default` clean 构建通过（见提交信息）。

## 插入菜单最终状态

| 序位 | 原版项 | Harmony 状态 |
|------|--------|--------------|
| 1 | Add Files | P657 实现（into-note 四类物化） |
| 2 | Add Photo | 已有 |
| 3 | Take Photo | 已有 |
| 4 | Add GIF（旗标） | **fail-closed 登记（本阶段）** |
| 5 | Insert Math（旗标） | 已有 |
