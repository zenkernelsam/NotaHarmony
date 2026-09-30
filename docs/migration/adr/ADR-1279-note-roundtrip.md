# ADR-1279：`.note` 导出↔导入往返

## 状态

已接受（Phase 1336）。

## 决策

`.note` 导出 = ZIP{manifest.json+pages+note.assets+
recordings.json}（对照 `yk9`），与 `NoteImporter` 读
路径对称 —— 往返无损闭环。

## 理由

`NoteExporter` 写 ZIP：manifest+`pages/page_N.json`+
`note.assets` 录音资产（对照 `yk9`/`v6d.j`/`zk9.a`），
`MissingAssetsException` 缺资产 fail-closed；`NoteImporter`
+`SessionParser`+`BinaryPlistParser` 读同一布局（Session.
plist/GLKeyedArchiver）—— 导出所写即导入所读。

## 后果

`.note` 导出↔导入往返闭合 —— 数据可移植性保真。
