# ADR-1232：桌面 widget

## 状态

已接受（Phase 1288）。

## 决策

AppWidgetProvider/Glance → Harmony `FormExtensionAbility`
+`formProvider` 服务卡片；RemoteViews 列表 → Form 卡片。

## 理由

5 个 widget：CreateNote/CreateRecording（快捷入口）+
FolderNotes/RecentNotes（`qk9` Glance 集合列表）+
NoteThumbnail（`ec0`+`fzi.d` 位图缩放）+WidgetImage
Provider（ContentProvider image/png）+2 配置 Activity。

## 后果

Harmony 桌面入口 = 服务卡片（FormExtensionAbility） —
— 快捷新建+笔记列表+缩略图卡片，widget→卡片映射。
