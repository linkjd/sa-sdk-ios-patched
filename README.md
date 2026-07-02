# SensorsAnalyticsSDK-Patched

基于神策分析 SDK (v4.9.1) 的定制版本，增加了 SM3 国密签名等自定义功能。

## 原始项目

- 仓库：https://github.com/sensorsdata/sa-sdk-ios
- 许可：商业许可协议（详见 LICENSE）

## 定制内容

- 新增 SM3 国密算法签名（HMAC-SM3）
- 请求参数自动加签，签名结果写入 HTTP 请求头 `X-Sign`
- 支持通过 `setSecretKey:` 动态设置签名密钥

## 集成方式

```ruby
pod 'SensorsAnalyticsSDK-Patched', :git => 'https://github.com/linkjd/sa-sdk-ios-patched.git', :tag => 'v4.9.1'
```

## 代码导入

```objc
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>
```

## License

本项目基于神策分析 SDK 商业许可协议，详见 [LICENSE](LICENSE)。
