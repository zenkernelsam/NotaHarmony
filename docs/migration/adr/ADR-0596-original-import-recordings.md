# ADR-0596: .note 录音实体以 recordings.json 清单往返

- 状态：accepted（2026-09-28，Phase 627）
- 前置：ADR-0595（录音字节并入 assets/）、T-026（包结构）

## 背景

Phase 626 把录音音频字节并入 `.note` 的 `assets/` 内容寻址
集合，但包内不携带录音实体——Harmony 的 `.note` 格式没有
原版 `noteBundle` 的 flatbuffer 同步 op 流。原版 `yk9` 经
ops 序列化 CREATE_RECORDING（`yk9.O` 分享开关为真时），
导入端 `zl8`/`cl9` 重放 ops 还原录音行与资产引用；Harmony
端再导入自己的包时 `original_recording_state` 零恢复，
录音整体丢失。

## 决定

以 JSON 清单 `recordings.json` 等价承载实体序列化：

1. **格式**：`{ version: 1, recordings: [...] }`，每录音
   携带 `{timestamp, siteId, name, startTime, endTime,
   segments, zIndex, assetHashBits, assetFileName,
   assetMimeType, assetFileSize}`——即
   `original_recording_state` 的可序列化列；
2. **导出**：`listVisible` 全量落清单；空则省略条目
   （清单可缺省）；
3. **导入**：实体行先于资产字节落库——
   `insertImportedOriginalRecording` 按 `applyCreate` 同列集
   插行 + `mergeOriginalAssetReference` 建 PENDING
   `note_asset`，既有 `storeImportedOriginalAsset` 循环把
   `assets/<hash>` 字节升级 LOCAL；
4. **校验**：清单结构与原版 `yn2.a` CREATE_RECORDING 解码
   同界（段仅查 `endTime ≤ 录音 endTime` 一侧）；清单损坏
   或资产元数据冲突 → CORRUPTED，不静默丢录音；
5. **不引入 ops 流**：Harmony 导入路径对页面元素同样直插
   行不重放 ops，录音保持一致；create_signature 采用与
   `createSignature` 同形的 JSON 摘要，仅作身份幂等令牌。

## 备选（否决）

- **内嵌 flatbuffer ops**：与 `encodeOriginalLocalCreateRecording`
  能力不符（它只写 metadata+start/end，丢 name/segments/
  zIndex）；为导入补一套完整编码器收益低、风险高。
- **塞进 manifest.json**：manifest 定位是包级身份/页数，
  录音是实体集合——独立条目与 `pages/` 模式一致，且老读
  者天然忽略未知条目。

## 后果

- 本端 `.note` 导出→导入往返后录音实体、名字、分段、
  zIndex、资产引用全部还原，资产字节在时立即可播；
- 资产缺失时录音行保留为 PENDING/MISSING（与图片/PDF
  缺资产语义一致）；
- 原版 `.note`/`x59` 分享包的 `Recordings/` 音频导入仍属
  `importNotability` 外部格式缺口（仅计数），不在本 Phase。
