# ADR-1215：Volley HTTP 栈

## 状态

已接受（Phase 1271）。

## 决策

`ywb`/`bw8`/`jwb`/`d34` Volley 栈 → Harmony `rcp`/`http`
+`taskpool` 请求队列。

## 理由

`ywb`=RequestQueue（cache+network PriorityBlockingQueue+
`bw8[]` NetworkDispatcher 线程+`ub` 主线程投递）；
`jwb`=优先级 Request；`d34`=投递 Runnable —— 完整
Volley HTTP 栈（Rive CDN + App 网络）。

## 后果

Harmony HTTP = rcp/http+taskpool+优先级队列 ——
网络栈语义保真。
