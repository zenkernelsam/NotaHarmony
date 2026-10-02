# Phase 1453 报告：选区旋转柄 90° 角度吸附（guf.e / twm.d / vtf）

## 触发

追查 1.4.2 选区自由变换会话族（`xtf` Move / `vtf` Rotate /
`wtf` Scale / `ttf` Shape）时发现 `guf` 上的吸附函数——Harmony
旋转柄此前为纯自由角。

## 原版证据链

1. **`guf` 静态字段**：`m=fq9.z(5f)`=5° 弧度阈值；
   `n={-V,-V/2,0,V/2,V}`（`V=si5.a`=π，`fbc:37` 以 0/π 旋转对照
   坐实）→ 吸附集 {-180°,-90°,0°,90°,180°}。
2. **`guf.e(j, vtf)`**：`atan2(cur − centerAbsolute)` → 遍历 `n`
   找 |差|<m 的吸附角 → 减 `vtf.i()=startingRadians`。
3. **`vtf` toString**：`Rotate(stateId, originalPositions,
   dragStartPoint, centerAbsolute, startingRadians, …)`——枢轴=
   选区中心（与 Harmony `resizeAnchor=resizeBaseCenter` 一致）。
4. **`ms1:525`**：startingRadians = 起始指针角；`yj8.G`（RTL 左柄）
   时 +π。
5. **`twm.d`**：捏合会话（`guf.v`/utf）同款 90°/5° 吸附。
6. **`wtf`**（角柄 Scale 会话）：axis/xAxis/yAxis +
   `locksAspectRatio`（lsf+文本块=false 自由拉伸，余 true）+
   fixedCorner——**无角度字段**：1.4.2 角柄拖拽不产旋转
   （版本演进：1.0.3 `htc.e` 角柄=缩放+旋转自由变换）。

## Harmony 修改

`applySelectionResize`：旋转柄支的绝对指针角先吸附最近 90° 倍数
（`SELECTION_ROTATE_SNAP_RAD`=5°），再减起始角。角柄支不变
（登记差异，待 `guf.r/s` 可解码后裁）。

## 验证

- `d02-original-selection-rotate-snap`：13 项绿（含可执行模型）。
- `d02-original-selection-resize`：29 项绿（pin 更新）。
- 全量基线 / 双 HAP：待跑。

## 遗留

- `wtf` 双轴缩放 + `locksAspectRatio` + 角柄无旋转：登记差异
  （`guf.r/s` 反编译失败，应用语义待旁证）。
- `ttf`（lsf 形状顶点拖拽重构会话）未审计——顶点拖拽是否允许
  逐顶点变形形状待查。
- RTL 左柄 +π 起始角（依赖 P1450 RTL 锚位登记项）。
