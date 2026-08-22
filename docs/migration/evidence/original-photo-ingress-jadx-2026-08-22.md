# Phase 282 原版照片 Ingress 逆向证据（2026-08-22）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`（只读）。本文件只记录
与 Phase 282 决策相关的硬证据，不在 Desktop 写入任何 Harmony 工作树。

## 1. URI 复制与 100 MiB 上限

`bgj.java:185-330`：

- `bgj.d(Context, Uri)` 调用 `context.getContentResolver().openInputStream(uri)`；
- `File.createTempFile("temp_", null, context.getCacheDir())` 创建 cache 临时文件；
- `fag.z(inputStreamOpenInputStream, bufferedOutputStream, 104857600L)` 的上限是 `104857600L`；
- 超限分支记录 `Dropped image exceeds max file size`、`file.max_bytes=104857600L`，删除临时文件并返回失败；
- MIME 为空时 fallback 到 `"image/*"`，再交给 `vuh.b(fileCreateTempFile, strI)`；
- 成功返回 `frf(new je4(...), fileCreateTempFile)`；失败类型包括 `hrf`（不可用）与 `grf`（超限）。

Harmony 对应：常量 `ORIGINAL_PHOTO_MAX_BYTES = 104857600`；读取器允许读入上限加 1 byte，再统一拒绝空/
超限，避免截断内容被当作完整图片；cache 路径由调用方显式提供，临时文件在 finally 中清理。

## 2. 选中列表 all-or-nothing

`tf9.java` 的 `B(Object)`：

- 输入 `List` 与 `Context`；
- 校验协程返回 `true` 时执行 `gl8Var.setValue(list)`；
- 返回 `false` 时执行 `((wx4) this.L).invoke(list, null)`，即整体失败回调；
- 没有部分通过后继续处理的分支。

`lb.java:345` 的 case 8 把 picker 返回的 `List` 交给 `new tf9(..., 21)`。因此列表校验在进入单 URI ingress
前发生。

## 3. 图片扩展名 allowlist

`oj3.java` 的图片扩展名集合包含：

```text
png, jpg, jpeg, webp, tif, tiff, gif, heif, heic
```

Harmony `SUPPORTED_EXTENSIONS` 原样保留该顺序；无扩展名、隐藏名 `.png` 与未支持扩展名都 fail closed。
`tf9` 的具体 picker contract 因 JADX 方法体未完全反编译而未声称逐字节复现；本阶段只固定其可证的
all-or-nothing 语义。

## 4. Harmony SDK 证据

本地 DevEco SDK：

`C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.file.picker.d.ts`

- `PhotoSelectOptions` / `PhotoSelectResult` / `PhotoViewPicker.select()` 声明存在；
- `PhotoSelectResult.photoUris` 为 URI 列表；
- Phase 282 只把 URI 列表作为输入，不启动 picker，也不声明真实 provider URI 的设备兼容性。

CoreFileKit `@ohos.file.fs` 提供 `openSync/statSync/readSync/writeSync/closeSync/unlinkSync/accessSync`，
用于有界读取、cache copy 与清理。

## 5. 明确证据边界

- `tf9.D` 方法体被 JADX 标记为反编译失败，因此不推断具体 picker launch 参数；
- 未找到 `bgj.d` 的直接静态调用点，调用链可能经 lambda/synthetic bridge；本阶段不伪造该缺失链路；
- 未做设备运行，因此 HEIC/HEIF/TIFF/GIF decode、权限、provider URI 与性能均未验收；
- `T-042` 不在本阶段处理。
