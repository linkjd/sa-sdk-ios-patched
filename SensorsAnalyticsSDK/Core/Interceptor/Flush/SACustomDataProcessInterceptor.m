//
// SACustomDataProcessInterceptor.m
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
// 在数据上传前对请求参数进行签名加密处理
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag
#endif

#import "SACustomDataProcessInterceptor.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import <CommonCrypto/CommonDigest.h>

@implementation SACustomDataProcessInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    
    // [自定义修改] 在数据压缩编码前，对请求参数进行签名加密
    if (input.json.length > 0) {
        @try {
            NSString *sign = [self signStringWithJSONString:input.json];
            if (sign.length > 0) {
                // [自定义修改] 将签名结果设置到 customHeaders 的 "sign" 字段
                // SAFlushInterceptor 会自动将 customHeaders 应用到 HTTP 请求头中
                NSMutableDictionary *headers = [input.customHeaders mutableCopy] ?: [NSMutableDictionary dictionary];
                headers[@"sign"] = sign;
                input.customHeaders = [headers copy];
                SALogDebug(@"[自定义修改] Sign header set successfully");
            }
        } @catch (NSException *exception) {
            SALogError(@"[自定义修改] Sign processing failed: %@", exception);
        }
    }
    
    completion(input);
}

// [自定义修改] 对请求参数进行签名加密（预留方法）
// 当前实现为示例逻辑：对 JSON 字符串做 SHA256 哈希
// 后续可替换为具体的加密算法（如 HMAC-SHA256、RSA 等）
- (nullable NSString *)signStringWithJSONString:(NSString *)jsonString {
    if (jsonString.length == 0) {
        return nil;
    }
    
    @try {
        // ============================================================
        // [自定义修改] 签名加密预留方法
        // ============================================================
        // TODO: 在此处替换为具体的加密算法实现，例如：
        //   - HMAC-SHA256 签名（需要密钥）
        //   - RSA 非对称加密签名
        //   - 自定义业务签名逻辑
        // ============================================================
        
        // 示例实现：对 JSON 字符串计算 SHA256 哈希作为签名
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(jsonData.bytes, (CC_LONG)jsonData.length, hash);
        
        NSMutableString *signString = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [signString appendFormat:@"%02x", hash[i]];
        }
        
        return [signString copy];
    } @catch (NSException *exception) {
        SALogError(@"[自定义修改] signStringWithJSONString failed: %@", exception);
        return nil;
    }
}

@end
