//
// SACustomDataProcessInterceptor.h
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// [自定义修改] 自定义数据处理拦截器
/// 在 flush_json 之后、flush_http_body 之前执行
/// 用于在数据正式提交到接口之前
@interface SACustomDataProcessInterceptor : SAInterceptor

/// [自定义修改] 对请求参数进行签名加密
/// @param jsonString 待签名的 JSON 字符串（请求参数）
/// @return 签名加密后的字符串，用于设置到请求头的 "sign" 字段
- (nullable NSString *)signStringWithJSONString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
