//
// SACustomDataProcessInterceptor.h
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
// 在数据上传前对请求参数进行 SM3 国密签名加密处理
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// [自定义修改] 自定义数据处理拦截器
/// 在 flush_json 之后、flush_http_body 之前执行
/// 用于在数据正式提交到接口之前，对请求参数进行 SM3 国密签名加密
/// 签名结果存储在请求头的 "X-Sign" 字段中
///
/// @discussion
/// 签名密钥通过 SDK 初始化时设置：
/// @code
/// // 启用签名
/// [[SensorsAnalyticsSDK sharedInstance] setSecretKey:@"your-secret-key"];
///
/// // 禁用签名
/// [[SensorsAnalyticsSDK sharedInstance] setSecretKey:nil];
/// @endcode
@interface SACustomDataProcessInterceptor : SAInterceptor

@end

NS_ASSUME_NONNULL_END
