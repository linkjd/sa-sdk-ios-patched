# SensorsAnalyticsSDK (iOS v4.9.1) 项目结构与网络请求框架分析

## 一、项目概况

**项目名称**: SensorsAnalyticsSDK（神策数据 iOS SDK）
**版本**: 4.9.1
**用途**: 提供 iOS 端数据埋点采集、事件追踪、用户行为分析等功能，支持自动采集（AutoTrack）、App 推送、深度链接（DeepLink）、加密等功能。

---

## 二、主要目录结构与模块划分

### 2.1 顶层目录

```
SensorsAnalyticsSDK/                  # SDK 核心源码
├── Core/                             # 核心框架（Builder/Flow/Network/Interceptor 等）
├── AutoTrack/                        # 自动埋点模块
├── AppExtension/                     # App Extension 支持
├── AppPush/                          # 推送模块
├── ChannelMatch/                     # 渠道匹配模块
├── Deeplink/                         # 深度链接模块
├── Encrypt/                          # 数据加密模块
├── Exception/                        # 异常捕获模块
├── Location/                         # 地理位置模块
├── RemoteConfig/                     # 远程配置模块
├── Store/                            # 本地存储插件
├── UIRelated/                        # UI 相关工具（元素路径、View 属性等）
├── WKWebView/                        # WebView 打通模块
└── Resources/                        # 资源文件（PrivacyInfo.xcprivacy）

Example/                              # 示例工程
├── SensorsData/                      # Objective-C 示例
└── SensorsDataSwift/                 # Swift 示例

SensorsAnalyticsSDK.xcodeproj/        # Xcode 项目文件
SensorsAnalyticsSDK.xcworkspace/      # Xcode Workspace
```

### 2.2 Core 核心模块细分

```
Core/
├── Builder/                          # 事件构建
│   ├── EventObject/                  # 事件对象模型（基类、Track、Profile、Item、SignUp、Bind、Unbind）
│   ├── SAIdentifier.h/m             # 用户标识管理（匿名 ID、登录 ID、distinctId）
│   ├── SAPresetPropertyObject.h/m   # 预置属性
│   └── SASessionProperty.h/m        # Session 属性
├── EventTrackerPlugin/               # 事件跟踪插件协议及管理
├── Flow/                             # 数据流引擎（核心架构）
│   ├── SAFlowManager.h/m            # 流程管理器（注册、启动 Flow）
│   ├── SAFlowObject.h/m             # Flow 对象定义
│   ├── SATaskObject.h/m             # Task 对象定义
│   ├── SANodeObject.h/m             # Node 节点定义
│   ├── SAFlowData.h/m               # 数据流转载体
│   └── SAInterceptor.h/m            # 拦截器基类
├── Interceptor/                      # 拦截器实现（业务逻辑单元）
│   ├── EventBuild/                   # 事件构建拦截器链
│   │   ├── SACorrectUserIdInterceptor    # 用户 ID 校正
│   │   ├── SADynamicSuperPropertyInterceptor  # 动态公共属性
│   │   ├── SAEventCallbackInterceptor     # 事件回调
│   │   ├── SAEventResultInterceptor      # 事件结果构建
│   │   ├── SAEventValidateInterceptor    # 事件校验
│   │   ├── SAIDMappingInterceptor        # ID-Mapping
│   │   ├── SAPropertyInterceptor         # 属性采集
│   │   └── SASerialQueueInterceptor      # 串行队列切换
│   ├── Flush/                        # 数据上报拦截器链
│   │   ├── SACanFlushInterceptor         # 网络状态/策略判断
│   │   ├── SAFlushHTTPBodyInterceptor    # HTTP Body 构建
│   │   ├── SAFlushInterceptor            # 网络请求发送（核心）
│   │   ├── SAFlushJSONInterceptor        # JSON 拼接组装
│   │   └── SARepeatFlushInterceptor      # 循环上报
│   └── Datebase/                     # 数据库 CRUD 拦截器
│       ├── SADatabaseInterceptor
│       ├── SADeleteRecordInterceptor
│       ├── SAInsertRecordInterceptor
│       ├── SAQueryRecordInterceptor
│       └── SAUpdateRecordInterceptor
├── Network/                          # 网络状态相关
│   ├── SANetwork.h/m                 # 网络管理器（Cookie/ServerURL）
│   ├── SANetworkInfoPropertyPlugin   # 网络信息属性插件
│   └── SAReachability.h/m           # 网络状态监听
├── PropertyPlugin/                   # 属性插件体系
│   ├── PresetProperty/               # 预置属性插件
│   │   ├── SAPresetPropertyPlugin
│   │   ├── SAAppVersionPropertyPlugin
│   │   ├── SADeviceIDPropertyPlugin
│   │   └── SAFirstDayPropertyPlugin
│   └── SuperProperty/               # 公共属性插件
│       ├── SASuperPropertyPlugin
│       └── SADynamicSuperPropertyPlugin
├── Tracker/                          # 数据库存储
│   ├── SADatabase.h/m               # 数据库封装
│   ├── SAEventRecord.h/m            # 事件记录模型
│   └── SAEventStore.h/m             # 事件存储管理
├── Utils/                            # 工具类
├── SAHTTPSession.h/m                 # HTTP 会话层（基于 NSURLSession）
├── SASecurityPolicy.h/m              # HTTPS 证书验证策略
├── SAConfigOptions.h/m               # SDK 配置选项
├── SAConstants.h/m                   # 常量定义
├── SensorsAnalyticsSDK.h/m           # SDK 主入口
└── ...
```

---

## 三、组件依赖关系与数据流向

### 3.1 整体架构分层

```
┌─────────────────────────────────────────────────────────────────┐
│                      SensorsAnalyticsSDK                         │
│                      （SDK 主入口 / 对外 API）                    │
├─────────────────────────────────────────────────────────────────┤
│                        SAFlowManager                            │
│                     （数据流引擎 / 调度中心）                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ EventBuild  │→ │  Database   │→ │   Flush     │              │
│  │ Interceptor │  │ Interceptor │  │ Interceptor │              │
│  │   (Chain)   │  │   (Chain)   │  │   (Chain)   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│  SAHTTPSession    │   SANetwork     │   SAReachability          │
│  (NSURLSession)   │  (Cookie管理)   │  (网络状态监听)            │
├─────────────────────────────────────────────────────────────────┤
│  PropertyPluginManager  │  EncryptManager  │  ModuleManager     │
│  (属性插件体系)         │  (加密模块)      │  (功能模块管理)     │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 数据流向（事件追踪 → 上报）

整个事件处理流程由 **SAFlowManager** 编排，基于 Flow → Task → Node 三级结构。定义在 `SACoreResources` 中的 3 个 Flow 及其数据流如下：

#### Flow 1: Track Flow (`sensorsdata_track_flow`)

```
trackEventObject 输入
       │
       ▼
[Node] SADynamicSuperPropertyInterceptor  ── 采集动态公共属性
       │
       ▼
[Node] SASerialQueueInterceptor  ── 切换到串行队列
       │
       ▼
──── Task: track_task ────
       │
       ▼
[Node] SARemoteConfigInterceptor  ── 远程配置检查
       │
       ▼
[Node] SAEventValidateInterceptor  ── 事件名校验
       │
       ▼
[Node] SAIDMappingInterceptor  ── ID-Mapping 处理
       │
       ▼
[Node] SACorrectUserIdInterceptor  ── 用户 ID 校正
       │
       ▼
[Node] SAPropertyInterceptor  ── 采集属性（预置/公共/自定义）
       │
       ▼
[Node] SAEventCallbackInterceptor  ── 事件回调（外部自定义拦截）
       │
       ▼
[Node] SAEventResultInterceptor  ── 构建事件 JSON、生成 Record
       │
       ▼
[Node] SAEncryptInterceptor  ── 事件加密（可选）
       │
       ▼
[Node] SAInsertRecordInterceptor  ── 存入本地数据库
       │
       ▼
──── Task: flush_task ────  (自动触发/手动触发)
```

#### Flow 2: Flush Flow (`sensorsdata_flush_flow`)

```
flushAllEventRecords 输入
       │
       ▼
[Node] SASerialQueueInterceptor  ── 切串行队列
       │
       ▼
[Node] SACanFlushInterceptor  ── 检查网络策略（是否允许上报）
       │
       ▼
[Node] SAQueryRecordInterceptor  ── 从数据库查询待上报记录
       │
       ▼
[Node] SAEncryptInterceptor  ── 读取时加密（可选）
       │
       ▼
[Node] SAUpdateRecordInterceptor  ── 更新记录状态为"上报中"
       │
       ▼
[Node] SAFlushJSONInterceptor  ── 多条记录拼接为 JSON
       │
       ▼
[Node] SAFlushHTTPBodyInterceptor  ── JSON → Gzip → Base64 → HTTP Body
       │
       ▼
[Node] SAFlushInterceptor  ── 发送 HTTP POST 请求（核心网络请求）
       │
       ▼
[Node] SASerialQueueInterceptor (sync)  ── 同步回主队列
       │
       ▼
[Node] SADeleteRecordInterceptor  ── 上报成功，删除数据库记录
       │
       ▼
[Node] SARepeatFlushInterceptor  ── 循环上报（最多40次），直至无数据
```

#### Flow 3: Ads Flush Flow (`sensorsdata_ads_flush_flow`)

用于广告事件的独立上报通道，流程与 Flush Flow 类似但更精简。

### 3.3 主要依赖关系

| 组件 | 依赖 |
|------|------|
| SensorsAnalyticsSDK | SAFlowManager, SANetwork, SAConfigOptions, SAHTTPSession, SAIdentifier, SAEventStore, SATrackTimer, SAPropertyPluginManager |
| SAFlowManager | SAFlowObject, SATaskObject, SANodeObject, SAInterceptor |
| SAFlushInterceptor | SAHTTPSession, SAURLUtils, SAModuleManager |
| SAHTTPSession | NSURLSession, SASecurityPolicy |
| SANetwork | SAURLUtils, SAHTTPSession |
| SAPropertyPluginManager | SAPropertyPlugin（多种子类插件） |
| SAEncryptManager | SAEncryptProtocol, SAAlgorithmProtocol（AES/RSA/ECC 等） |

---

## 四、网络请求框架详细分析

### 4.1 网络请求架构总览

SDK 的网络请求分为**三层架构**：

```
┌──────────────────────────────────────────────────────────────┐
│  SAFlushInterceptor  (发送层 - 构建 Request + 发起请求)      │
│  路径: Core/Interceptor/Flush/SAFlushInterceptor.h/m        │
├──────────────────────────────────────────────────────────────┤
│  SAFlushHTTPBodyInterceptor (Body 构建层 - Gzip + Base64)    │
│  路径: Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.h/m │
├──────────────────────────────────────────────────────────────┤
│  SAHTTPSession  (传输层 - NSURLSession 封装 + 证书验证)      │
│  路径: Core/SAHTTPSession.h/m                               │
├──────────────────────────────────────────────────────────────┤
│  SASecurityPolicy  (安全层 - SSL Pinning 证书验证)           │
│  路径: Core/SASecurityPolicy.h/m                             │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 各网络组件详细说明

#### 4.2.1 SAHTTPSession — HTTP 会话层（最底层网络传输）

- **文件**: [Core/SAHTTPSession.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAHTTPSession.h), [Core/SAHTTPSession.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAHTTPSession.m)
- **功能**: 基于 NSURLSession 的轻量级 HTTP 客户端封装
- **核心方法**:
  - `-dataTaskWithRequest:completionHandler:` — 创建并返回 NSURLSessionDataTask
- **安全特性**:
  - 实现 `NSURLSessionDelegate` 和 `NSURLSessionTaskDelegate` 协议
  - 支持 `sessionDidReceiveAuthenticationChallengeBlock` — Session 级别证书验证回调
  - 支持 `taskDidReceiveAuthenticationChallengeBlock` — Task 级别证书验证回调
  - 持有 `SASecurityPolicy` 实例进行 SSL Pinning 验证
- **配置**: 使用 `ephemeralSessionConfiguration`（不持久化缓存/Cookie），超时 30 秒
- **属性**:
  - `securityPolicy` — 证书验证策略
  - `delegateQueue` — 串行代理队列

#### 4.2.2 SASecurityPolicy — 安全策略（证书验证）

- **文件**: [Core/SASecurityPolicy.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SASecurityPolicy.h), [Core/SASecurityPolicy.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SASecurityPolicy.m)
- **功能**: HTTPS 证书验证策略，参考 AFNetworking 实现
- **验证模式**:
  - `SASSLPinningModeNone` — 不验证证书
  - `SASSLPinningModePublicKey` — 验证公钥
  - `SASSLPinningModeCertificate` — 验证完整证书
- **核心方法**:
  - `+defaultPolicy` — 默认策略（SASSLPinningModeNone）
  - `-evaluateServerTrust:forDomain:` — 评估服务器信任
- **配置方式**: 通过 `SAConfigOptions.securityPolicy` 属性设置

#### 4.2.3 SANetwork — 网络管理器（高级封装）

- **文件**: [Core/Network/SANetwork.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Network/SANetwork.h), [Core/Network/SANetwork.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Network/SANetwork.m)
- **功能**: 管理 Cookie 和 ServerURL 解析
- **核心功能**:
  - `setCookie:isEncoded:` / `cookieWithDecoded:` — Cookie 存取
  - `serverURL` — 构建完整的数据接收 URL（支持 debug mode 参数拼接）
  - `host` / `project` / `token` — 从 serverURL 解析出各组成部分
  - `isSameProjectWithURLString:` — 判断是否同项目
  - `isValidServerURL` — 验证 serverURL 有效性

#### 4.2.4 SAFlushInterceptor — 核心请求发送拦截器

- **文件**: [Core/Interceptor/Flush/SAFlushInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushInterceptor.h), [Core/Interceptor/Flush/SAFlushInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushInterceptor.m)
- **功能**: 构建 HTTP 请求并发起网络调用
- **核心方法**:
  - `buildFlushRequestWithInput:` — 构建 NSURLRequest
    - HTTP Method: POST
    - 超时: 30 秒
    - User-Agent: `SensorsAnalytics iOS SDK`
    - Dry-Run Header: debugOnly 模式下添加 `Dry-Run: true`
    - Cookie: 从 input 传入
    - URL: 由 serverURL + debug mode 参数构建
  - `requestWithInput:completion:` — 通过 SAHTTPSession 发起请求，处理返回结果
    - 正常 (200-299): 视为成功
    - 5xx/404/403: 视为失败（不删除记录，后续重试）
    - 其他: 视为成功（删除记录）
  - `eventLogsWithInput:` — 日志打印

#### 4.2.5 SAFlushHTTPBodyInterceptor — HTTP Body 构建

- **文件**: [Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.h), [Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.m)
- **功能**: 将 JSON 数据 → Gzip 压缩 → Base64 编码 → URL 编码 → 组装 POST Body
- **Body 格式**: `crc=<hashcode>&gzip=<1|9|13>&data_list=<encoded_data>[&instant_event=true][&sink_name=mirror]`

#### 4.2.6 SAFlushJSONInterceptor — JSON 拼接

- **文件**: [Core/Interceptor/Flush/SAFlushJSONInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushJSONInterceptor.h), [Core/Interceptor/Flush/SAFlushJSONInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushJSONInterceptor.m)
- **功能**: 将多条 EventRecord 拼接为 JSON 数组字符串 `[{...},{...}]`

#### 4.2.7 SACanFlushInterceptor — 刷新条件判断

- **文件**: [Core/Interceptor/Flush/SACanFlushInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SACanFlushInterceptor.h), [Core/Interceptor/Flush/SACanFlushInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SACanFlushInterceptor.m)
- **功能**: 判断当前网络类型是否符合刷新策略，不符合则终止流程

#### 4.2.8 加密相关网络拦截器扩展

- **SAFlushJSONInterceptor+Encrypt**: [Encrypt/SAFlushJSONInterceptor+Encrypt.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Encrypt/SAFlushJSONInterceptor+Encrypt.h), [Encrypt/SAFlushJSONInterceptor+Encrypt.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Encrypt/SAFlushJSONInterceptor+Encrypt.m)
- **SAFlushHTTPBodyInterceptor+Encrypt**: [Encrypt/SAFlushHTTPBodyInterceptor+Encrypt.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Encrypt/SAFlushHTTPBodyInterceptor+Encrypt.h), [Encrypt/SAFlushHTTPBodyInterceptor+Encrypt.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Encrypt/SAFlushHTTPBodyInterceptor+Encrypt.m)

### 4.3 网络请求完整调用栈

```
用户触发 track 或 flush
       │
       ▼
SensorsAnalyticsSDK.track: / trackEventObject:
       │ 构建 SAFlowData → 调用 SAFlowManager.startWithFlowID(kSATrackFlowId)
       ▼
SAFlowManager → Flow Engine → EventBuild Interceptor Chain
       │ 事件构建完成 → 存入数据库
       ▼
SensorsAnalyticsSDK.flush: / 定时器触发的 flush
       │ 构建 SAFlowData → 调用 SAFlowManager.startWithFlowID(kSAFlushFlowId)
       ▼
SAFlowManager → Flush Interceptor Chain:
  1. SACanFlushInterceptor         (检查网络策略)
  2. SAQueryRecordInterceptor      (查询数据库)
  3. SAEncryptInterceptor          (可选的加密)
  4. SAUpdateRecordInterceptor     (标记状态)
  5. SAFlushJSONInterceptor        (拼 JSON)
  6. SAFlushHTTPBodyInterceptor    (Gzip + Base64 → Body)
  7. SAFlushInterceptor            (核心网络请求)
       │
       ▼
SAHTTPSession.dataTaskWithRequest:  →  NSURLSession  →  HTTP POST
       │
       ▼
响应回调 → 状态码判断 → SADeleteRecordInterceptor (删除已上报记录)
       │
       ▼
SARepeatFlushInterceptor  → 继续循环上报
```

### 4.4 网络请求关键配置项

| 配置项 | 说明 | 默认值 | 设置方式 |
|--------|------|--------|----------|
| `serverURL` | 数据接收地址 | 无（必填） | `SAConfigOptions.initWithServerURL:` |
| `flushNetworkPolicy` | 上报网络策略 | 3G/4G/WIFI | `configOptions.flushNetworkPolicy` |
| `flushInterval` | 上报间隔（毫秒） | 15000 | `configOptions.flushInterval` |
| `flushBulkSize` | 触发上报的缓存事件数 | 100 | `configOptions.flushBulkSize` |
| `maxCacheSize` | 本地最大缓存事件数 | 10000 | `configOptions.maxCacheSize` |
| `securityPolicy` | HTTPS 证书验证策略 | defaultPolicy | `configOptions.securityPolicy` |
| `debugMode` | Debug 模式 | Off | `configOptions.debugMode` |
| `flushBeforeEnterBackground` | 后台时等待上报完成 | NO | `configOptions.flushBeforeEnterBackground` |
| `enableEncrypt` | 是否启用加密 | NO | `SAConfigOptions+Encrypt` |

---

## 五、自定义网络请求指南

### 5.1 自定义请求头

要自定义请求头，可以在 `SAFlushInterceptor` 的 `buildFlushRequestWithInput:` 方法中进行修改。

**文件位置**: [Core/Interceptor/Flush/SAFlushInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushInterceptor.m)

关键代码（第 105-120 行）：

```objc
- (NSURLRequest *)buildFlushRequestWithInput:(SAFlowData *)input {
    // ... 构建 URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = @"POST";
    request.HTTPBody = input.HTTPBody;
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    if (input.configOptions.debugMode == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }
    if (input.cookie) {
        [request setValue:input.cookie forHTTPHeaderField:@"Cookie"];
    }
    return request;
}
```

**自定义方案**:
- 直接修改 `SAFlushInterceptor` 的 `buildFlushRequestWithInput:` 方法，在返回 request 前添加自定义 header
- 或通过 Category 扩展 `SAFlushInterceptor` 添加自定义 header 逻辑

### 5.2 自定义拦截器

SDK 的拦截器系统基于 `SAInterceptor` 基类构建。要添加自定义拦截器：

**步骤 1**: 创建自定义拦截器继承 `SAInterceptor`

```objc
// 继承 SAInterceptor
@interface SACustomHeaderInterceptor : SAInterceptor
@end

@implementation SACustomHeaderInterceptor
- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    // 在这里处理自定义逻辑（如修改请求头、过滤事件等）
    completion(input);  // 必须调用 completion
}
@end
```

**步骤 2**: 注册到 Flow 流程中

方式一：通过代码在初始化后注册 Flow

```objc
// 在 SDK 初始化后
SAFlowManager *manager = [SAFlowManager sharedInstance];

// 1. 创建节点
SANodeObject *customNode = [[SANodeObject alloc] init];
customNode.nodeID = @"custom_header";
customNode.interceptor = [[SACustomHeaderInterceptor alloc] init];

// 2. 注册节点
[manager registerNodes:@[customNode]];

// 3. 创建或替换 Task
SATaskObject *flushTask = [manager taskForID:@"flush_task"];
// 将自定义节点插入到 flush 节点的前面
```

方式二：修改 `SACoreResources` 中的节点配置（在 `sensors_analytics_node.json` 中添加新节点，并在 `sensors_analytics_task.json` 的对应 task 中添加节点 ID）

### 5.3 自定义 SAHTTPSession（底层传输）

如需替代整个网络传输层：

- **文件**: [Core/SAHTTPSession.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAHTTPSession.m)
- 可以直接修改 `SAHTTPSession` 的 `dataTaskWithRequest:completionHandler:` 方法
- 或替换 `SAHTTPSession` 中的 `NSURLSession` 配置（如超时、缓存策略等）

### 5.4 自定义请求拦截（通过 SAEventCallbackInterceptor）

SDK 提供了 `trackEventCallback` 回调接口，可以自定义事件拦截逻辑：

```objc
SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
[sdk registerEventCallback:^BOOL(NSString *eventName, NSMutableDictionary *properties) {
    // 自定义逻辑
    if ([eventName isEqualToString:@"$AppStart"]) {
        // 修改属性
        properties[@"custom_key"] = @"custom_value";
    }
    return YES; // 返回 NO 则丢弃该事件
}];
```

**文件位置**: [Core/Interceptor/EventBuild/SAEventCallbackInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/EventBuild/SAEventCallbackInterceptor.m)

---

## 六、关键文件索引

| 文件路径 | 说明 |
|----------|------|
| [SensorsAnalyticsSDK.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SensorsAnalyticsSDK.h) | SDK 主入口头文件 |
| [SensorsAnalyticsSDK.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SensorsAnalyticsSDK.m) | SDK 主实现（初始化、track、flush 等） |
| [SAConfigOptions.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAConfigOptions.h) | 配置选项 |
| [SAHTTPSession.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAHTTPSession.h) | HTTP 会话层 |
| [SAHTTPSession.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SAHTTPSession.m) | HTTP 会话实现（NSURLSession 封装） |
| [SASecurityPolicy.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SASecurityPolicy.h) | HTTPS 安全策略 |
| [SANetwork.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Network/SANetwork.h) | 网络管理器 |
| [SAFlushInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushInterceptor.h) | 核心请求发送拦截器 |
| [SAFlushInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushInterceptor.m) | 核心请求发送实现 |
| [SAFlushHTTPBodyInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushHTTPBodyInterceptor.m) | HTTP Body 构建 |
| [SAFlushJSONInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SAFlushJSONInterceptor.m) | JSON 拼接组装 |
| [SACanFlushInterceptor.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Interceptor/Flush/SACanFlushInterceptor.m) | 网络策略判断 |
| [SAFlowManager.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Flow/SAFlowManager.h) | 数据流引擎管理器 |
| [SAFlowManager.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Flow/SAFlowManager.m) | 数据流引擎实现 |
| [SAInterceptor.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Flow/SAInterceptor.h) | 拦截器基类 |
| [SAFlowData.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Flow/SAFlowData.h) | 数据流传输对象 |
| [SACoreResources.m](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/SACoreResources.m) | Flow/Task/Node 配置定义 |
| [SAURLUtils.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Utils/SAURLUtils.h) | URL 工具类 |
| [SAReachability.h](file:///Users/linxiaoke/Desktop/sa-sdk-ios-4.9.1/SensorsAnalyticsSDK/Core/Network/SAReachability.h) | 网络状态监听 |
