# ADR-0415: 照片 Picker 原始资产门禁裁决

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 283 接入 `photoAccessHelper.PhotoViewPicker` 后只读取 `photoUris`。本地 SDK
`PhotoSelectResult.isOriginalPhoto` 明确表示所选媒体是否为原图，默认值为 `false`；若系统返回
压缩、转换或非原始资产，后续 100 MiB 读取与 Phase 281 规范化会把该结果继续伪装成原版
original image 链路。

## 决策

1. 生产 picker 选择上限提取为 `ORIGINAL_PHOTO_PICKER_MAX_SELECTION = 500`，保持既有产品契约并便于静态验证。
2. 每次 `select()` 成功后必须检查 `result.isOriginalPhoto === true`；非原始资产立即 fail closed，
   不返回 URI 列表，也不进入临时复制或持久化。
3. 用户取消和空选择继续由既有空列表校验处理；原始资产门禁只裁决系统返回的资产形态。
4. 真实设备 provider URI 权限、格式矩阵和性能验收继续开放，本阶段不冒充运行态结论。

## 结果

照片入口从 URI 列表扩展为“原始资产 + 有序列表”双重契约。非原图结果在 ingress 前被拒绝，
原版 100 MiB 与大图规范化语义只作用于可声称的 original photo。
