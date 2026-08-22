# Harmony 照片插入后首帧不可见证据

证据时间：2026-08-23（Asia/Shanghai）
范围：正式仓 Phase 289～291 当前源码静态链路复核。

## Runtime 顺序

1. `insertOriginalPhotos()` 成功获得 `finalImages`；
2. 推入同一个可撤销 `ADD_ELEMENTS` action；
3. 当前页匹配时执行：
   - `this.imageBlocks = this.imageBlocks.concat(finalImages);`
   - `synchronizeElementArraysByOrder();`
   - `updateSelectionOverlay();`
   - `renderFrame();`
4. 缺失步骤：没有调用 `refreshImageAssets()`。

## 为什么 hub 补救不成立

`StrokePersistence.commitOriginalImageInsert()` 在数据库提交后发布
`assetAvailabilityHub.publish(completed.storageHash, noteIds)`。但发布发生在 caller 安装 `imageBlocks`
之前。`onImageAssetAvailabilityChanged()` 只在当前 `imageBlocks` 中找到相同 storageHash 才调用
`refreshImageAssets()`；因此本次插入触发的自身 arrival event 无法命中新 block。

## 渲染约束

`renderFrame()` 对 IMAGE block 要求：

```text
imageAssets.get(storageHash)
loaded.state === ImageAssetLoadState.READY
loaded.bitmap !== null
```

新插入路径没有发起 `loadImageAsset()`，所以缓存为空且首帧不画。重启后的页面加载路径调用
`refreshImageAssets()`，这解释了“重启后才显示”的现象。

## 修复点

安装 final images 后立即调用 `refreshImageAssets(generation, pageId)`，再同步 order 与重绘。
异步 load 完成时继续使用既有 generation/page guard 和强制重绘。
