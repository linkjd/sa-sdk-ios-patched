//
// SACustomDataProcessInterceptor.m
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
// 在数据上传前对请求参数进行 SM3 国密签名加密处理
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag
#endif

#import "SACustomDataProcessInterceptor.h"
#import "SM3Utils.h"
#import "SALog.h"

@implementation SACustomDataProcessInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    
    // [自定义修改] 判断 secretKey 是否存在，决定是否需要签名
    // 当 secretKey 为 nil 或空字符串时，跳过签名流程，直接进行数据传输
    if (input.json.length > 0 && input.secretKey.length > 0) {
        @try {
            NSString *sign = [self signStringWithJSONString:input.json secretKey:input.secretKey];
            if (sign.length > 0) {
                // [自定义修改] 将 SM3 签名结果设置到 customHeaders 的 "X-Sign" 字段
                // SAFlushInterceptor 会自动将 customHeaders 应用到 HTTP 请求头中
                NSMutableDictionary *headers = [input.customHeaders mutableCopy] ?: [NSMutableDictionary dictionary];
                headers[@"X-Sign"] = sign;
                input.customHeaders = [headers copy];
                SALogDebug(@"[自定义修改] X-Sign header set successfully");
            }
        } @catch (NSException *exception) {
            SALogError(@"[自定义修改] SM3 sign processing failed: %@", exception);
        }
    } else {
        // [自定义修改] secretKey 不存在，跳过签名流程
        SALogDebug(@"[自定义修改] SecretKey is nil or empty, skip signing");
    }
    
    completion(input);
}

// [自定义修改] 使用 SM3 国密算法对请求参数进行签名加密
// @param jsonString 待签名的 JSON 字符串（请求参数）
// @param secretKey SM3 签名密钥，通过 SDK 初始化时传入
// @return SM3 签名加密后的十六进制字符串
- (nullable NSString *)signStringWithJSONString:(NSString *)jsonString secretKey:(NSString *)secretKey {
    if (jsonString.length == 0 || secretKey.length == 0) {
        return nil;
    }
    
    @try {
        // [自定义修改] 构建待签名数据：JSON 数据 + 密钥
        NSMutableString *dataToSign = [NSMutableString stringWithString:jsonString];
        [dataToSign appendString:secretKey];
        
        // [自定义修改] 使用 SM3Utils 计算 SM3 哈希（十六进制字符串）
        NSString *signString = [SM3Utils sm3HexWithString:dataToSign];
        
        if (signString.length == 0) {
            SALogError(@"[自定义修改] SM3 hash result is empty");
            return nil;
        }
        
        return signString;
    } @catch (NSException *exception) {
        SALogError(@"[自定义修改] signStringWithJSONString failed: %@", exception);
        return nil;
    }
}

@end
