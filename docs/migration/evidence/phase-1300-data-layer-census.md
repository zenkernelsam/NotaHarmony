# Phase 1300（里程碑）证据 — 数据层+应用架构总普查

来源：`com/gingerlabs/notability/` 全树收敛（Phase
1283–1299 汇总）。

## 应用架构总图

```
app/             应用壳 —— NbApplication(Hilt DI)+
                 MainActivity(Compose)+Startup 链+
                 widgets×5+升级 Receiver+原生回退
auth/            OAuth —— Google(GMS)+Microsoft+Apple
core/            基础设施 —— analytics(性能span)+logging(NbLog)+
                 memory(SharedMemory)+flatbuffers+glmath+
                 model+network+retrofit+user
data/            数据层 —— billing×2+learn+library(导出/ntb)+
                 note(ops/assets/state)+search(FTS/AppSearch)+
                 settings/toolbar+transcription+handwriting
domain/          subscription（订阅领域）
feature/         login(OAuth)+editor+...
```

## 数据层 = 8 Room 库 + CRDT ops + 资产同步

- **8 Room DB**：Learn/Search(+Index)/Settings/Toolbox/
  Transcription/NoteAsset/NoteState/NoteBundleMetadata。
- **CRDT ops**：`haa` 32-op + `ops/synced` 5 异常冲突。
- **资产同步**：NoteAsset Transfer/Download/Upload workers。
- **导出**：`.ntb` ZIP bundle + `ExportFileProvider` +
  `nj3` MIME 注册表。

## 语义

**分层架构** —— 壳(compose+Hilt)/领域/数据(Room+CRDT+
资产)/基础设施/集成(billing×2+OAuth×3+GMS+MyScript+
PDFTron) —— 完整移动笔记应用架构。

## Harmony 决策

各层映射均已建立（前面各 ADR）—— 架构分层语义保真。

## 产出

- fixture `d02-data-layer-census.mjs`（10 断言）。
- ADR-1244；中文报告。
