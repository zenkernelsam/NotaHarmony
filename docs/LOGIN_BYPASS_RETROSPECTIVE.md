# Notability 登录绕过完整复盘：从登录页、加载圈到资料库主页面

> 日期：2026-08-02  
> 环境：Windows + MuMu 模拟器 + Frida 16.1.11  
> 最终结果：成功从冷启动跳过登录，导航进入 `o77` 资料库主页面，并可打开真实笔记编辑器。  
> 研究边界：只用于本地模拟器、离线 UI 与架构研究；不包含真实账户、云端数据或服务端权限。

---

## 1. 一句话结论

这次最关键的认识是：

> **登录页上的“用户状态”不等于应用底层真正认可的“当前用户”。**

最初只伪造 `LoginState(zn7)`，最多只能骗过 Compose 登录界面；主导航随后仍会等待底层用户仓库 `hnf.e/f`。只有同时补齐 UI 状态、完整用户流、用户身份流和导航防回退逻辑，应用才会真正进入资料库。

最终验证链如下：

```text
r26.a = TRUE
    +
zn7.user != null && zn7.initializedLogin == false
    ↓
un7 调用 resetToLibraryOrSurvey()
    ↓
hp8 读取 first(hnf.e)
    ↓
hnf.e 立即返回 fake vmf，hnf.f 返回 fake tmf
    ↓
导航栈 si7 → o77
    ↓
资料库主页面与笔记编辑器正常渲染
```

---

## 2. 最终成果与证据

当前可用脚本：

- [`frida_scripts/bypass_login_v14.py`](frida_scripts/bypass_login_v14.py)

运行时关键日志：

```text
[+] fake vmf ready: User(
    id=00000000-0000-0001-0000-000000000001,
    name=Local User,
    email=local@local.dev,
    authToken=offline-local-token,
    useType=PERSONAL,
    isAiEnabled=false,
    isBusiness=false
)
[+] hnf.e replaced: kbb, replay emit=true
[+] hnf.f replaced: knd, value=00000000-0000-0001-0000-000000000001
[NAV STACK] [si7]
[NAV STACK] [o77]
```

其中：

- `si7` 是启动阶段观察到的过渡路由。
- `o77` 是 `LibraryRoute`；其内部再分发 Home、Notes、Shared 与 Folder 内容。
- `dn7` 是 LoginRoute。
- `f89` 是带笔记 ID 的笔记页面路由。

资料库壳（当前截图为 **Notes 选中态**，不是真正 Home 内容）：

![Notability v14 资料库 Notes 选中态](Screenshot/notability_v14_home.png)

真实笔记编辑器：

![Notability v14 笔记编辑器](Screenshot/notability_v14.png)

验证不只停留在“画面看起来像成功”：

- 左侧 Home、Notes、Shared with me、Folders 均已渲染。
- All Notes、Recent、Favorites、Unfiled 标签均已渲染。
- 本地笔记卡片可以显示。
- 可以进入 New Note 编辑器。
- 画笔、荧光笔、橡皮擦、文本、选区、录音、页面管理器等编辑工具均已渲染。
- 20 秒诊断日志确认导航栈真正进入 `o77`，不是覆盖在登录页上的假 UI。
- Frida 诊断进程退出后，当前应用实例仍保持在资料库页面；但下次冷启动仍需重新注入。

---

## 3. 先把环境钉死：Frida 混乱是第一类假问题

这次曾经同时出现三套 Python/Frida 来源：

1. Windows 系统 Python 3.12。
2. Codex bundled Python runtime。
3. 项目内临时安装的 `.tools/frida_py`。

这会制造一种很危险的错觉：

> 命令能运行，不代表运行的是同一套 Frida。

最终统一使用下面这套环境：

| 项目 | 已验证值 |
|---|---|
| Python | `C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe` |
| Python 版本 | 3.12.10 |
| Frida Python 包 | 16.1.11 |
| Frida CLI | `C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\Scripts\frida-ps.exe` |
| frida-server | 16.1.11 Android x86_64 |
| ADB | `C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe` |
| MuMu ADB | `127.0.0.1:7555` |
| MuMu Frida | `127.0.0.1:27042` |
| 包名 | `com.gingerlabs.notability` |

### 3.1 三条环境铁律

第一，电脑端 `frida` 和模拟器内 `frida-server` 必须完全同版本。

```text
client 16.1.11 ↔ server 16.1.11
```

第二，MuMu 内核是 x86_64，因此必须运行 Android x86_64 版 frida-server。即使安装包中存在 `arm64_v8a` split，也不能据此选择 arm64 server。Frida 要匹配的是模拟器运行内核/进程环境，不是 APK 文件名。

第三，本机有多个 ADB 设备时，每条设备命令都必须显式指定：

```powershell
-s 127.0.0.1:7555
```

否则很可能把截图、启动、停止或安装命令发给错误设备。

### 3.2 推荐的环境自检

```powershell
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -c "import frida; print(frida.__version__)"

& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\Scripts\frida-ps.exe" `
  --version

& "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe" `
  -s 127.0.0.1:7555 get-state

& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\Scripts\frida-ps.exe" `
  -H 127.0.0.1:27042
```

四项都成功后再分析应用。否则后续看到的“Hook 没生效”“类找不到”“进程突然退出”，可能都只是环境噪声。

---

## 4. 混淆类名重新校准

逆向混淆应用最容易出现的问题，是给一个类过早贴上“真实身份”，然后所有推理都围绕错误身份展开。

本次最终确认的关键映射如下：

| 混淆名 | 实际职责 | 证据 |
|---|---|---|
| `un7` | LoginScreen Compose 入口 | 包含登录状态读取及跳转条件 |
| `dn7` | LoginRoute | `aq8.s()` 最终把栈重置为它 |
| `o77` | `LibraryRoute` | `aq8.r()` 最终把栈重置为它；页面内部再选择 Home/Notes/Shared/Folder |
| `si7` | 启动/过渡路由 | 运行时导航栈首次观察到它 |
| `f89` | 笔记详情/编辑路由 | 含 `iof` 笔记 ID 等字段 |
| `zn7` | LoginState | 字段包含 user、loginInProgress、initializedLogin 等 |
| `go7` | LoginViewModel | 管理登录状态流 |
| `fo7` | LoginState reducer | 生成/更新 `zn7` |
| `vmf` | 完整 User | ID、姓名、邮箱、token、persona、AI/Business 标记 |
| `tmf` | 当前用户身份 | 包装一个 `iof` 用户 ID |
| `iof` | 128 位 ID/UUID 类值对象 | 两个 long 构造，字符串表现为 UUID |
| `lnf` | 用户 persona/use type | BUSINESS、EDUCATOR、PERSONAL、STUDENT 等 |
| `hnf` | 用户域服务/用户仓库门面 | 暴露完整用户流 `e` 与身份流 `f` |
| `nmf` | 用户持久化数据源 | currentUserId、authToken、currentUserEmail 等 |
| `knd` | MutableStateFlow 实现 | `getValue()`、`k()`、`j()`、`emit()` |
| `c3d` | MutableSharedFlow 实现 | 支持 replay 与 emit/tryEmit |
| `kbb` | SharedFlow 只读包装 | 内部包装 `c3d` |
| `ind` | StateFlow 接口 | 暴露 `getValue()` |
| `aq8` | 主导航协调器 | 管理导航栈和 resetToLibrary/resetToLogin |
| `jk8` | 导航栈辅助器 | 提交并保存主导航栈 |
| `hp8` | 多用途导航协程 | case 5 等待 `first(hnf.e)` |
| `cr4` | 强制登出事件服务 | `a(String)` 发出登出事件 |
| `we0` | MeQuery 会话验证 | 403 时触发 `cr4.a("MeQuery 403")` |
| `r26.a` | Compose 初始化 CompositionLocal | 登录页根据它判断初始化阶段 |

两项重要纠错：

- `v38` 不是内容路由器。
- `yw2` 是多用途合成 Lambda，不是“注入 11 个 ViewModel 的主界面外壳”。

### 心得

混淆名映射必须满足至少一种可验证证据：

- 构造参数和字段结构吻合。
- 调用者/被调用者关系吻合。
- 运行时调用栈吻合。
- Hook 后可观察到预期状态变化。

仅凭“这个类看起来很大”或“它被很多地方调用”来命名，通常会把探索带入歧路。

---

## 5. v13 为什么失败：一个布尔值的语义完全反了

v13 的核心做法是把每次 `zn7` 发射重建为：

```text
user = fakeUser
loginInProgress = false
initializedLogin = true
```

直觉上，这似乎很合理：用户非空，而且“登录已经初始化”。但 [`un7.java`](decompiled/sources/defpackage/un7.java) 中真正的条件是：

```java
if (zn7Var2.a != null && !zn7Var2.c) {
    function0.invoke();
}
```

对应关系：

```text
zn7.a = user
zn7.c = initializedLogin
```

因此实际条件是：

```text
user != null && initializedLogin == false
```

只有满足它，LoginScreen 才会调用 `resetToLibraryOrSurvey()`。

这意味着 v13 的 `initializedLogin=true` 恰好阻止了页面跳转。

### 为什么字段名会骗人

`initializedLogin` 很可能不是“允许进入主界面”的授权位，而是“登录初始化流程已经消费/完成”的状态位。当前 UI 逻辑需要在“用户刚出现且初始化动作尚未消费”时触发一次跳转，所以判断使用 `!initializedLogin`。

### 对照实验

我们没有立刻大改脚本，而是只替换一个变量进行对照：

| 实验 | fake user | initializedLogin | 结果 |
|---|---:|---:|---|
| 原 v13 | 有 | `true` | 稳定留在登录页 |
| 单变量修改 | 有 | `false` | 离开登录页，进入全屏加载圈 |

第二个结果极其重要：它证明 `un7` 条件已经突破，同时告诉我们下一个阻塞点位于登录 UI 之后。

### 心得

布尔字段名只是提示，不是语义证明。对混淆/反编译代码，应该优先相信：

1. 精确分支表达式。
2. 单变量运行时实验。
3. 分支之后实际调用了什么。

---

## 6. 加载圈不是失败，而是下一层状态机暴露出来了

把 `initializedLogin` 改为 `false` 后，应用成功离开登录页，却停在全屏 ProgressBar。

如果只看 UI，很容易得出“脚本还是没成功”。但从状态机角度看，加载圈其实说明：

- 登录 Compose 分支已经通过。
- `resetToLibraryOrSurvey()` 已经开始执行。
- 某个异步依赖没有返回。

沿着调用链继续追踪，最终在 [`hp8.java`](decompiled/sources/defpackage/hp8.java) 的 case 5 找到：

```java
kbb kbbVar = aq8Var.N.e;
objU = bp.U(kbbVar, this);
```

`bp.U(flow, continuation)` 对应等待 Flow 的第一个值，也就是类似 Kotlin Flow 的 `first()`。

这里：

```text
aq8.N = hnf
hnf.e = 当前完整用户 vmf 的 Flow
```

v13 只伪造了 LoginScreen 使用的 `zn7.user`，并没有改变底层 `hnf.e`。所以：

```text
LoginState.user = fake vmf
hnf.e = 仍然没有当前用户
```

页面表面上“有用户”，导航域却永远等不到用户，于是协程挂起并持续显示加载圈。

### 第二个底层状态：hnf.f

[`hnf.java`](decompiled/sources/defpackage/hnf.java) 暴露两个关键字段：

```java
public final kbb e; // 完整 vmf 用户 Flow
public final ind f; // tmf 用户身份 StateFlow
```

`aq8` 和其他主界面 ViewModel 还会组合订阅 `hnf.f`。因此只让 `first(hnf.e)` 返回一次 fake user 仍不够稳固；连续消费者也必须看到一致的 fake identity。

### 心得

遇到无限加载时，最有效的问题不是“哪个 UI 在画 ProgressBar”，而是：

> **哪个协程、Future、Promise 或 Flow 正在等待一个永远不会出现的值？**

对于 Kotlin/Compose 应用，应重点搜索：

- `first()` / `firstOrNull()` 对应的反编译 helper。
- `collect()` / `stateIn()` / `combine()`。
- continuation 返回 `COROUTINE_SUSPENDED` 的位置。
- 导航操作之前的异步读取。

---

## 7. v14 的完整设计

v14 不再把问题视为“把登录页藏起来”，而是构造一套最小、自洽的离线用户世界。

### 7.1 构造一致的假用户对象

对象关系如下：

```text
iof fakeId
 ├── tmf(fakeId)                   当前身份
 └── vmf(fakeId, ..., PERSONAL)    完整用户
```

实际值：

```text
ID:        00000000-0000-0001-0000-000000000001
Name:      Local User
Email:     local@local.dev
Token:     offline-local-token
Persona:   PERSONAL
AI:        false
Business:  false
```

ID、身份和完整用户必须引用同一个 `iof`。如果它们互不一致，后续按用户 ID 分区的数据库、笔记仓库或导航逻辑可能再次分叉。

### 7.2 修正 LoginState

`knd` 是应用使用的 MutableStateFlow 实现。反编译结果显示：

- `emit()` 最终进入 `j()`。
- `j()` 最终进入 `k()`。
- `e()` 和 `i()` 也会走同一个核心更新路径。

因此 v14 Hook：

```text
knd.$init(Object)
knd.k(Object expected, Object next)
```

当值的运行时类为 `zn7` 时，重建为：

```text
user = fake vmf
loginInProgress = false
initializedLogin = false
其余弹窗/错误状态 = false 或 null
```

Hook 核心更新入口比同时 Hook 五六个表层方法更干净，也减少重复重建和日志噪声。

### 7.3 在 hnf 构造后替换两个底层用户流

目标构造器：

```text
hnf.$init(w55, nmf, cr4, ou6)
```

必须先调用原构造器，再替换字段，因为原构造器负责创建 `hnf.e/f` 及其协程作用域。

完整用户流 `hnf.e` 的字段类型固定为 `kbb`，不能直接塞一个 `knd`。v14 的做法是：

```text
c3d(replay=1, capacity=1, SUSPEND)
    ↓ tryEmit(fake vmf)
kbb(c3d)
    ↓ reflection
hnf.e
```

身份流 `hnf.f` 声明为 `ind`，而 `knd` 实现了 `ind`，所以可以：

```text
knd(fake tmf)
    ↓ reflection
hnf.f
```

这两个字段在 Java 中是 `final`，但实例字段可通过反射 `setAccessible(true)` 在当前 ART 环境中替换。运行日志已确认反射后的类型和值正确。

### 7.4 为什么不用 d3d.a() 工厂

反编译类 `d3d` 同时存在：

```text
静态字段 a
静态方法 a(...)
```

Frida Java Bridge 遇到同名字段/方法时容易产生访问歧义。因此 v14 直接调用 `c3d` 构造器：

```text
c3d.$new(1, 1, x31.SUSPEND)
```

这比猜测 Frida 的 `_a` 字段转义规则更稳定。

### 7.5 为 final 字段替换准备窄范围 fallback

如果某个 ART/JIT 环境忽略了 `hnf.e` 的 final 字段反射写入，`hp8` 仍可能读取旧 Flow。

因此 v14 额外 Hook：

```text
bp.U(sj4 flow, ce2 continuation)
```

但它不会全局篡改所有 Flow 的 `first()`。脚本只记录原始和替换后的 `hnf.e` 对象，并在参数与这些对象相同时返回 fake `vmf`。

这是一个重要原则：

> fallback 应该尽可能窄，只修正已知目标，避免破坏其他协程语义。

### 7.6 强制 Compose 初始化标记

`r26.a` 是 LoginScreen 读取的 CompositionLocal。v14 没有硬编码混淆 key，而是：

1. 反射读取 `r26.a` 内部的 key。
2. Hook `xi7.K(jda, h1b)`。
3. 只有传入 CompositionLocal 的 key 与目标 key 相等时，返回 `Boolean.TRUE`。

这样不会把应用内所有布尔 CompositionLocal 都改成 true。

### 7.7 阻断强制登出链

服务端 MeQuery 返回 403 时：

```text
we0
  ↓
cr4.a("MeQuery 403")
  ↓
cr4.b 事件流
  ↓
aq8 订阅者
  ↓
aq8.s() resetToLogin
  ↓
dn7 LoginRoute
```

v14 做两层保护：

- Hook `cr4.a(String)`，不发出强制登出事件。
- Hook `aq8.s()`，如果仍有其他路径请求 resetToLogin，则改为调用 `aq8.r()`。

[`t78.java`](decompiled/sources/defpackage/t78.java) 明确证明：

```text
t78 case 6 → 清空栈并加入 o77
t78 case 7 → 清空栈并加入 dn7
```

因此 `aq8.r()` 与 `aq8.s()` 的真实语义不是猜测，而是由 reducer 行为直接确认。

### 7.8 导航诊断比截图更重要

v14 Hook `jk8.e(...)`，记录每次真正提交的导航栈；同时短时轮询 `aq8.b0` 作为补充。

这解决了一个常见误判：

- 截图看到主界面，可能只是登录 Activity 上覆盖了一个临时 Composable。
- 导航栈进入 `[o77]`，才能证明主导航状态机已经认可资料库路由。

---

## 8. 完整复现步骤

### 8.1 启动并检查 ADB

```powershell
$ADB = "C:\Users\Cisco He\Desktop\Git\SchoolBox\Tools\platform-tools_ADB\adb.exe"

& $ADB connect 127.0.0.1:7555
& $ADB -s 127.0.0.1:7555 get-state
```

期望输出：

```text
device
```

### 8.2 启动 frida-server

```powershell
& $ADB -s 127.0.0.1:7555 shell `
  "su -c 'chmod 755 /data/local/tmp/frida-server-x86_64; nohup /data/local/tmp/frida-server-x86_64 > /dev/null 2>&1 &'"

& $ADB -s 127.0.0.1:7555 forward tcp:27042 tcp:27042
```

验证：

```powershell
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\Scripts\frida-ps.exe" `
  -H 127.0.0.1:27042
```

### 8.3 正常运行 v14

```powershell
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -u "C:\Users\Cisco He\Desktop\Notability\frida_scripts\bypass_login_v14.py"
```

脚本使用 spawn 模式，会自行启动并在进程恢复前安装 Hook。正常使用时保持终端运行，按 `Ctrl+C` 停止。

### 8.4 自动诊断模式

```powershell
& "C:\Users\Cisco He\AppData\Local\Programs\Python\Python312\python.exe" `
  -u "C:\Users\Cisco He\Desktop\Notability\frida_scripts\bypass_login_v14.py" `
  --duration 20
```

`-u` 关闭 Python stdout 缓冲；`--duration 20` 让脚本在 20 秒后自动退出，适合自动化收集完整日志。

### 8.5 预期成功日志

至少应看到：

```text
[+] hnf.e replaced: kbb, replay emit=true
[+] hnf.f replaced: knd, value=...
```

正常情况下还会看到：

```text
[NAV STACK] [si7]
[NAV STACK] [o77]
```

有些启动在 12 秒内尚未提交导航日志，但 20 秒测试已稳定观察到 `o77`；因此自动诊断建议使用 20 秒而不是更短时间。

---

## 9. 症状 → 原因 → 对策

| 症状 | 最可能原因 | 对策 |
|---|---|---|
| 仍停在登录页 | `zn7.c` 被设为 true | 强制 `user != null && initializedLogin == false` |
| 离开登录页但全屏转圈 | `hnf.e` 没有产生完整 `vmf` | 替换 `hnf.e` 或对目标 Flow 的 `bp.U` 做窄范围 fallback |
| 主页面短暂出现后回登录 | `cr4` 登出事件或 `aq8.s()` 被调用 | block `cr4.a(String)`，将 `aq8.s()` 重定向到 `aq8.r()` |
| `hnf.e` 赋值类型错误 | 字段要求 `kbb`，不能直接放 `knd` | 用 `c3d` 发射用户，再用 `kbb` 包装 |
| 反射返回对象没有 `getValue()` | Frida 把 Field.get() 暴露为泛型 Object | `Java.cast(obj, Java.use('knd'))` 后再调用 |
| `d3d.a`/`lnd.a` 调用异常 | 同名静态字段和方法造成桥接歧义 | 直接构造 `c3d`/`knd` |
| `class not found defpackage.xxx` | 运行时类名不含包前缀或 classloader 不对 | 优先使用裸类名 `zn7`、`hnf`；必要时再定位 ClassLoader |
| `unable to perform ptrace getregs` | 使用了 arm64 frida-server | 换成 16.1.11 Android x86_64 server |
| `unable to communicate with frida-server` | client/server 版本不一致或端口未转发 | 两端固定 16.1.11，重新 forward 27042 |
| ADB 命令作用到错误设备 | 本机存在多个设备 | 每条命令固定 `-s 127.0.0.1:7555` |
| Python 能运行但 Frida 版本不对 | 启动了 Codex Python 或 `.tools/frida_py` | 使用系统 Python 的绝对路径 |
| 长时间看不到脚本日志 | stdout 缓冲或长进程输出未及时回收 | 使用 `python -u` 和 `--duration 20` |
| 诊断结束后下次启动又见登录页 | Hook 不持久化 | 每次冷启动都通过 v14 spawn 注入 |

---

## 10. 这次最值得保留的分析方法

### 10.1 分层看状态，不要把“用户”当成一个变量

这次至少存在四层不同状态：

```text
Compose 初始化状态      r26.a
登录页面展示状态        zn7
用户域真实状态          hnf.e / hnf.f
主导航状态              aq8 / jk8
```

它们之间有关联，但不是同一个东西。只改其中一层，其他层仍会把应用拉回真实状态。

以后分析任何现代客户端，都建议先画出：

- UI State
- Repository/Domain State
- Persistence State
- Navigation State
- Server Session State

### 10.2 对照实验比“大而全 Hook”更有价值

把 `initializedLogin=true` 单独改成 false，是本次突破的转折点。

一次只改变一个变量，可以明确回答：

- 登录页条件是否通过？
- 加载圈属于旧问题还是新问题？
- 下一层阻塞在哪里？

如果一次同时 Hook 十个方法，即使成功，也很难知道哪一项是真正原因；失败时更难定位。

### 10.3 把“新症状”当作进度信号

```text
登录页 → 加载圈 → 资料库 → 编辑器
```

每一种新画面都意味着状态机前进了一层。不要因为还没到终点，就把加载圈当成与登录页完全相同的失败。

### 10.4 无限等待优先找 suspend 点

Compose 只是表现层。真正阻塞通常发生在：

- Flow first/collect
- suspend repository call
- navigation reducer 前置条件
- 数据库首次加载

找到 `bp.U(hnf.e, continuation)` 后，加载圈立刻从“神秘 UI 问题”变成了“用户 Flow 没有首值”的确定问题。

### 10.5 运行时证据要形成闭环

本次使用了四类证据互相印证：

1. 反编译源码：确认条件与字段类型。
2. Frida 日志：确认 Hook 安装、对象创建和字段替换。
3. 导航栈：确认路由由 `si7` 进入 `o77`。
4. 截图与交互：确认资料库和编辑器真的可用。

只靠其中一种证据都可能误判。

### 10.6 Hook 越窄越安全

例如 `bp.U` 是通用 Flow helper。若全局让它返回 fake user，整个应用所有 `first()` 都会被破坏。

v14 只对已经记录的 `hnf.e` 实例生效。这种“按对象身份匹配”的 Hook 更容易维护，也更接近原程序语义。

### 10.7 不要删掉失败版本

`bypass_login_v13.py` 应保留，因为它清楚展示了：

- 只伪造 UI 状态会发生什么。
- `initializedLogin=true` 为什么错误。
- v14 相比 v13 多补了哪一层。

失败脚本是实验记录，不是垃圾文件。

---

## 11. 当前方案的边界

v14 的目标是本地 UI、导航和离线功能研究，不是建立真实登录会话。

目前可确认：

- 可以进入资料库。
- 可以打开本地笔记编辑器。
- 本地 UI 和大量编辑组件可用于逆向观察。
- 本地应用实例在 Frida 退出后仍可保持当前页面。

不能据此假设：

- Notability Cloud 可以正常同步。
- MeQuery 或其他需要真实 token 的 API 会成功。
- 分享、订阅、团队、AI、云备份等服务端功能可用。
- 冷启动后状态会永久保持；Hook 本身不是 APK 持久补丁。

如果后续目标只是研究画布、工具栏、笔迹、模板、文本、录音和本地数据结构，当前状态已经足够。若目标转向云端协议，则应使用合法测试账户并单独分析真实认证流程，而不是继续扩大 fake session。

---

## 12. 文件导航

| 文件 | 用途 |
|---|---|
| [`frida_scripts/bypass_login_v14.py`](frida_scripts/bypass_login_v14.py) | 当前成功脚本 |
| [`frida_scripts/bypass_login_v13.py`](frida_scripts/bypass_login_v13.py) | 失败对照实验 |
| [`decompiled/sources/defpackage/un7.java`](decompiled/sources/defpackage/un7.java) | LoginScreen 条件 |
| [`decompiled/sources/defpackage/zn7.java`](decompiled/sources/defpackage/zn7.java) | LoginState 字段定义 |
| [`decompiled/sources/defpackage/hnf.java`](decompiled/sources/defpackage/hnf.java) | 用户域服务与 e/f Flow |
| [`decompiled/sources/defpackage/hp8.java`](decompiled/sources/defpackage/hp8.java) | 等待 `first(hnf.e)` 的协程 |
| [`decompiled/sources/defpackage/aq8.java`](decompiled/sources/defpackage/aq8.java) | 主导航协调器 |
| [`decompiled/sources/defpackage/t78.java`](decompiled/sources/defpackage/t78.java) | o77/dn7 导航 reducer 证据 |
| [`decompiled/sources/defpackage/cr4.java`](decompiled/sources/defpackage/cr4.java) | 强制登出服务 |
| [`decompiled/sources/defpackage/we0.java`](decompiled/sources/defpackage/we0.java) | MeQuery 403 触发点 |
| [`ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) | 可复现环境清单 |
| [`PROJECT_HANDOVER.md`](PROJECT_HANDOVER.md) | 项目总交接入口 |

---

## 13. 给下一位接手者的话

如果只记住三件事，请记住：

1. `initializedLogin` 必须是 `false` 才会触发离开 LoginScreen。
2. 登录 UI 中的 fake user 不够，必须让 `hnf.e/f` 也拥有一致的用户。
3. 判断成功要看导航栈是否进入 `o77`，不要只看页面截图。

这次真正绕过的不是一张登录页面，而是把应用启动时分散在 Compose、StateFlow、用户仓库、协程和导航栈里的状态重新拼成了一套自洽模型。

也正因为如此，这次经历对鸿蒙移植很有价值：它暴露了原应用如何划分展示状态、用户域状态和导航状态。将来设计鸿蒙版时，应当保留这种职责分离，但要避免让启动流程依赖多个难以诊断、永远等待的隐式 Flow。

---

*最后更新：2026-08-02*  
*结论状态：已在本地 MuMu 环境复现成功*
