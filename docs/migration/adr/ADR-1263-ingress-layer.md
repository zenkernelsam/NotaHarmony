# ADR-1263：入站分流层

## 状态

已接受（Phase 1319）。

## 决策

Android intent/extra/URI → `Want`(uri/parameters) +
`unifiedDataChannel`+`pasteboard`+`cameraPicker`；
不支持语义 fail-closed。

## 理由

各 `Original*Ingress`（deep-link notability.com/authlink/
gallery/event + launch_action/start_camera + open-target
want.uri + 拖放 + 剪贴板 + 相机）—— 外部输入统一
分流，对照原版 intent 规则（py2/hv7/yy2），子域通配
等不支持项 fail-closed。

## 后果

入站语义保真（URI/动作/文件/拖放/剪贴板/相机）+
明确 fail-closed 边界 —— intent→want 映射。
