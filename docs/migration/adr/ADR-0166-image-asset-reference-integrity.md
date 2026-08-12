# ADR-0166：原版图片资产引用完整性

## 决策

原版图片资产入库与普通资产保存共享同一个事务内 `note_meta` 引用校验；直接写入
`note_asset` 的图片字节路径不得绕过该门禁。

## 原因

Phase188 只保护了 `AssetRepositoryImpl.saveAsset()`。`ImageAssetPackageStore` 直接
合并并写入 `note_asset`，导入或网络到达路径仍可能留下不存在的 note ID。

## 边界

历史孤儿引用仍需迁移扫描；本阶段阻止新路径继续制造孤儿。
