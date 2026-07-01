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
#import "SASM3.h"
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
            NSString *sign2 = [self signStringWithJSONString2:input.json secretKey:input.secretKey];
            SALogDebug(@"%@", sign2);
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
        
        // [自定义修改] 将字符串转换为 UTF-8 数据
        NSData *jsonData = [dataToSign dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData) {
            SALogError(@"[自定义修改] Failed to convert string to UTF-8 data");
            return nil;
        }
        
        // [自定义修改] 使用 SM3 算法计算哈希
        uint8_t digest[SM3_DIGEST_LENGTH];
        sa_sm3_hash((const uint8_t *)jsonData.bytes, jsonData.length, digest);
        
        // [自定义修改] 将哈希结果转换为十六进制字符串
        NSMutableString *signString = [NSMutableString stringWithCapacity:SM3_DIGEST_LENGTH * 2];
        for (int i = 0; i < SM3_DIGEST_LENGTH; i++) {
            [signString appendFormat:@"%02x", digest[i]];
        }
        
        return [signString copy];
    } @catch (NSException *exception) {
        SALogError(@"[自定义修改] signStringWithJSONString failed: %@", exception);
        return nil;
    }
}

- (nullable NSString *)signStringWithJSONString2:(NSString *)jsonString secretKey:(NSString *)secretKey {
    if (jsonString.length == 0 || secretKey.length == 0) {
        return nil;
    }
    
    @try {
        // [自定义修改] 构建待签名数据：JSON 数据 + 密钥
        NSMutableString *dataToSign = @"H4sIAAAAAAAAE%2B2by27bRhSG34X1UhbmSs5oZ8dx41UDuJdFURAUObQGoTgCObSrGgYadNNdU6DookDX3XVVFEFRoC8TB%2B1bdKiLrcSiJVmkEzMjLwQPD%2Bdy5vDDf%2BZQX547iTqRqS8jp%2BdAgQkNhIBxjCCMARdRxEMXhwAJzjyEgNNxtBwKpwc9hhiHHkaIso4TpCodD1WRTzsih4cuQ4/3dw/cPbpLiId3jTHZ3ff2HiPGkOeRfdOVOBWpNuY7e6PRsQ4ybdp8nQXhs0k3yCMMcux5vOPIyJhKLUXu9M6dndm/Y2MXn64/4PV9d5vw9f2bee2i44wyNRLZ1QKU%2BXLkJ8dlp8Fo5J%2BKLJcqLafSJV2vbM7DTIjUP5ORHjg97NGOk6lE%2BHo8MhvgmImIbJTJXBjjfJxrMZxfMh1OJpv7scxy7UfB2OnFQZIL0zpUkUjKwZ8OVCog6ODSNhKnMhSbOSMV%2Bkxlz%2BajfnF0eFQ2lwHyjenaV3GcC7O/u4QB056JvBgKP87U0O%2BbPT7JVJFG1xMr3ZAGZXA5//7z4r%2Bfvr38/ddXfz9/9fKXstczGUunp7NCXLtmIOTJwAzAIDKNiez7Q6EHqlxDUGj1aRlJzuzKooN5F5bNwyAt4iDURSYy026CMBFv%2BG0a6vP5qXyhE0i67qzrq40M1XAUpGO/mHgRIBpEkRtXhQUA872fmJubu%2BMi/VoGqh%2Bobj6QIxMvZeRMhjivXMXiDKpCqcI1pvNI5lqmod4EANPt1jPv%2BnFS5AN/EQuIU4xcftHZmi7MY7XQ5XMpzo4nQfMWYszADFBoCbOKMOax1snk2fzjt9d/vXggzNmAKUVWzvDJwcHHSkV5GTCPVKqNPxLzGG7OnJn5bPDqbtd5qpeSp4Je9wChSOhAVjvro8ln3bW9R8TywPbEKn3KG9JDGHCIKQIMVdNq09nXx6tNOGn1kNVDH5oe8uDWdGEQE4Ca1EOQcwww4Z5FjBVEVhB96IIIbY0sjjAktSDrUSKnk10QRJhD6kIOLK02p9WOSMTQ2MzNPzvaL7RW6eKl0MTwdAcuf/j59Z/ftw9y9wuxlZLJQqx%2BiOEaIEbNX2MQQ4Ag7lLXQsxCzELMQqwpiHFWT/K4DGIMGlvOsIXY9hAzsfu06BsnT1l2XPTDJMjzKqb9ePnyu7bmoJZsrScb2Z5smHBAtyXbkyiaPnVL8cZcE3vE5pl3OXgfRJEflk6txlarERWaVWxzsnUXulSd5b%2BD8/XJ8h8CQwhsSB0ZcnCXcExxu/mxBBQVEVKtjtbWQkuVzkp91GrQ3K6FjB9lErbz1L1ybQ9XF9EamEahS5osF7qYUmrAZrO%2BtbO%2BdudrVzXDW2GTiVhkhhf%2BzVR4KeTm9itzugZJ%2BFByQ0vCmyREACLg1fIi6RJ1hzjnDBAAWq7uGqTgkmP8IJsqviODx/ZxclMCWrhZuN0CN4gbfSuMINflhCFLOPtW2Kq3wm6Q7W3Ur6HwViLMnv63BX9uHfjj9WS5S7SdyyhniLo2wbVlzSbl31qQtOSz5HuTfCbt3Dqrva3uCSFFjGJIbeHTFj4bgNiKymhVEbMtvzy6h8qoVwtlWFP6CnqIAM8FwGs3YGxl9D0nkT1Ta5G0qgV6iINGf2lJIfA810Ww3eSztVNbO7UofGcoZBdf/Q9A99tg5EsAAA%3D%3D";
        
        // [自定义修改] 将字符串转换为 UTF-8 数据
        NSData *jsonData = [dataToSign dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData) {
            SALogError(@"[自定义修改] Failed to convert string to UTF-8 data");
            return nil;
        }
        
        // [自定义修改] 使用 SM3 算法计算哈希
        uint8_t digest[SM3_DIGEST_LENGTH];
        sa_sm3_hash((const uint8_t *)jsonData.bytes, jsonData.length, digest);
        
        // [自定义修改] 将哈希结果转换为十六进制字符串
        NSMutableString *signString = [NSMutableString stringWithCapacity:SM3_DIGEST_LENGTH * 2];
        for (int i = 0; i < SM3_DIGEST_LENGTH; i++) {
            [signString appendFormat:@"%02x", digest[i]];
        }
        
        return [signString copy];
    } @catch (NSException *exception) {
        SALogError(@"[自定义修改] signStringWithJSONString failed: %@", exception);
        return nil;
    }
}

@end
