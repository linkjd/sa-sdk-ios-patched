//
// SACustomDataProcessInterceptor.m
// SensorsAnalyticsSDK
//
// [自定义修改] 自定义数据处理拦截器
// 在数据上传前插入自定义处理逻辑
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag
#endif

#import "SACustomDataProcessInterceptor.h"
#import "SAJSONUtil.h"
#import "SALog.h"

@implementation SACustomDataProcessInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    
    // [自定义修改] 在数据压缩编码前处理 JSON 数据
    // 此处可以修改 input.json，添加自定义字段或修改现有数据
    if (input.json) {
        [self processCustomDataWithInput:input];
    }
    
    completion(input);
}

// [自定义修改] 自定义数据处理逻辑
- (void)processCustomDataWithInput:(SAFlowData *)input {
    @try {
        // 解析 JSON 字符串为数组
        NSData *jsonData = [input.json dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *events = [SAJSONUtil JSONObjectWithData:jsonData];
        
        if (![events isKindOfClass:[NSArray class]] || events.count == 0) {
            return;
        }
        
        // 在这里添加自定义处理逻辑
        // 例如：为每个事件添加自定义字段
        NSMutableArray *modifiedEvents = [NSMutableArray arrayWithCapacity:events.count];
        for (NSDictionary *event in events) {
            NSMutableDictionary *modifiedEvent = [event mutableCopy];
            
            // [示例] 添加自定义字段
            // modifiedEvent[@"custom_field"] = @"custom_value";
            
            [modifiedEvents addObject:modifiedEvent];
        }
        
        // 将修改后的数据转回 JSON 字符串
        NSData *modifiedJsonData = [SAJSONUtil dataWithJSONObject:modifiedEvents];
        if (modifiedJsonData) {
            input.json = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
        }
        
        SALogDebug(@"[自定义修改] Custom data processing completed");
    } @catch (NSException *exception) {
        SALogError(@"[自定义修改] Custom data processing failed: %@", exception);
    }
}

@end
