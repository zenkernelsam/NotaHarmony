# Phase 1271 证据 — ywb/bw8/jwb/d34 Volley HTTP 栈

来源：`defpackage/{ywb,bw8,jwb,d34,oyb,syb,ub,eg3}.java`
+ `com/android/volley/*`（~22 文件）。

## `ywb` = Volley `RequestQueue`

```java
AtomicInteger a;               // 序列号
HashSet b;                     // 当前请求集
PriorityBlockingQueue c, d;    // 缓存队列 + 网络队列
eg3 e;                         // Cache
rnh f;                         // dispatcher
ub g;                          // ResponseDelivery
bw8[] h;                       // NetworkDispatcher 线程池
u91 i;                         // 启动/停止
```

## `bw8` = `NetworkDispatcher`（网络工作线程）

`extends Thread` — `{BlockingQueue, rnh cache, eg3
network, ub delivery, volatile M quit}` + `addMarker
("network-http-complete")` + `notifyListenerResponse-
NotUsable` —— 从网络队列取 `jwb` 执行+投递。

## `jwb` = `Request` 基类

`implements Comparable` — `{String url, oyb listener}`
+ `addMarker`/`cancel`/`deliverError`/`deliverResponse`/
`getBody`/`getPriority` —— 优先级排序请求。

## `d34` = 响应投递 Runnable

`{ayi, teh, String}` + `VolleyError` + `Handler.post` —
— ExecutorDelivery 把响应/错误投到主线程。

## `oyb`/`syb`/`ub`/`eg3`

`oyb`=Request iface（优先级/取消）；`syb`=NetworkResponse；
`ub`=ResponseDelivery；`eg3`=Cache/Network。

## 语义

**完整 Volley HTTP 栈** —— RequestQueue 双队列（cache+
network）+ N NetworkDispatcher 线程 + 主线程投递 +
Request 优先级 —— Rive CDN 资源加载 + App 网络。

## Harmony 决策

Volley 栈 → Harmony `rcp`/`http`+`taskpool` 队列 —
— 请求队列+优先级+主线程投递语义保真。

## 产出

- fixture `d02-volley.mjs`（10 断言）。
- ADR-1215；中文报告。
