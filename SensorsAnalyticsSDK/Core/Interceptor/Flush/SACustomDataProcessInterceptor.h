//
// SACustomDataProcessInterceptor.h
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
// 在数据上传前插入自定义处理逻辑
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// [自定义修改] 自定义数据处理拦截器
/// 在 flush_json 之后、flush_http_body 之前执行（flush_json → custom_data_process → flush_http_body → flush）
/// 用于在数据正式提交到接口之前，插入自定义的数据处理逻辑
@interface SACustomDataProcessInterceptor : SAInterceptor

@end

NS_ASSUME_NONNULL_END
