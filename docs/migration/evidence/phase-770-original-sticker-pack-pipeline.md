# 原版 1.4.2 贴纸包安装/下载管道登记（Phase 770 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/sources/com/gingerlabs/notability/feature/note/stickers/packs/`
>   + `defpackage/{iwg,pq3,hwg,mo1,bwg,cwg,fwg}.java`
> 性质：1.4.2 版本差证据登记（Phase 763 stickers.apk 的运行时侧补全）；
>   无 Harmony 代码变更。

## 一、包解析双源（`pq3` implements `iwg`）

```text
resolve(pack):
  1) split 侧：gs7.a.b("stickers") 取 stickers split 安装目录，
     File(splitDir, packDir) 存在且经 bwg 校验 → 直接使用
  2) 远端回退：mo1.a(pack) —— CDN 下载
```

- `bwg` 校验器：枚举 `webp`/`png`/`jpg`/`jpeg` 扩展名，目录存在性检查
  （split 内每包为一目录，Phase 763 登记 39 包 ~2985 webp）。
- `mo1` 远端下载器：键 `cdn`、`sticker.pack`、`sticker.pack.delivery`、
  `sticker.pack.version`——CDN 按包名/投递通道/版本寻址。

## 二、下载状态登记（`hwg`）

- `ptg` StateFlow 持有已安装包 id 集（`y2g.c0` 并集追加）。
- `a8g` Channel → `p3e` 流：下载完成事件；`fwg` 状态枚举
  （F/G/H/I 四态——入队/跳过/成功/失败语义对应）。
- `a(cwg, fwg)`：成功态写集合 + 发通道事件。

## 三、WorkManager 双任务

| Worker | 注入 | 语义 |
|---|---|---|
| `StickerPackDownloadWorker` | `iwg` + `hwg` | 显式下载单包 |
| `StickerPackPrefetchWorker` | `iwg` + `hwg` | 预取（浏览商店时后台备包） |

两 Worker 同一协作对——prefetch 与 download 仅触发时机不同。

## 四、分类

**混合边界**：

- split 内 39 包为**可分发的本地资产**（webp + 目录结构），
  内容上可随 Harmony rawfile 打包；
- 远端回退（CDN + delivery/version 键）与商店目录属后端；
- 安装器架构依赖 Android split-APK 机制，Harmony 无等价
  split——若采纳贴纸，需重写为 rawfile 内置 + 文件目录解析。

登记为版本差·待审簇（资产可移植，管道需重设计）。
