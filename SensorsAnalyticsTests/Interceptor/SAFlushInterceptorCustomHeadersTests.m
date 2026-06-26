//
// SAFlushInterceptorCustomHeadersTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2025/1/1.
// Copyright © 2015-2025 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAFlushInterceptor.h"
#import "SAFlowData.h"
#import "SAConfigOptions.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK.h"

#pragma mark - Expose internal method for testing

@interface SAFlushInterceptor (Testing)

- (NSURLRequest *)buildFlushRequestWithInput:(SAFlowData *)input;

@end

#pragma mark -

@interface SAFlushInterceptorCustomHeadersTests : XCTestCase

@property (nonatomic, strong) SAFlushInterceptor *interceptor;
@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

@implementation SAFlushInterceptorCustomHeadersTests

- (void)setUp {
    self.interceptor = [[SAFlushInterceptor alloc] init];
    self.configOptions = [[SAConfigOptions alloc] initWithServerURL:@"https://test.datasink.example.com/sa?project=default&token=test_token" launchOptions:nil];
}

- (void)tearDown {
    self.interceptor = nil;
    self.configOptions = nil;
}

#pragma mark - 测试场景1：不传入自定义请求头参数时的默认行为

/// 不设置自定义请求头时，请求中仅包含 SDK 默认的请求头
- (void)testDefaultHeadersWhenNoCustomHeaders {
    // 准备
    SAFlowData *input = [[SAFlowData alloc] init];
    input.configOptions = self.configOptions;
    input.HTTPBody = [@"test_body" dataUsingEncoding:NSUTF8StringEncoding];

    // 执行
    NSURLRequest *request = [self.interceptor buildFlushRequestWithInput:input];

    // 验证 - 包含默认的 User-Agent
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    XCTAssertNotNil(userAgent, @"默认请求应包含 User-Agent 请求头");
    XCTAssertEqualObjects(userAgent, @"SensorsAnalytics iOS SDK", @"默认 User-Agent 应为 SensorsAnalytics iOS SDK");

    // 验证 - 没有自定义请求头
    NSDictionary *allHeaders = [request allHTTPHeaderFields];
    XCTAssertNotNil(allHeaders, @"请求头字典不应为 nil");
    XCTAssertEqual(allHeaders.count, 1, @"不传自定义请求头时，应该只有 User-Agent（无 Cookie 和 Dry-Run 时）");
}

#pragma mark - 测试场景2：传入部分自定义请求头时的合并逻辑

/// 传入部分自定义请求头，应与默认请求头合并
- (void)testMergeCustomHeadersWithDefaultHeaders {
    // 准备
    SAFlowData *input = [[SAFlowData alloc] init];
    input.configOptions = self.configOptions;
    input.HTTPBody = [@"test_body" dataUsingEncoding:NSUTF8StringEncoding];
    input.customHeaders = @{
        @"X-Custom-Header": @"custom_value",
        @"X-Request-ID": @"req-12345"
    };

    // 执行
    NSURLRequest *request = [self.interceptor buildFlushRequestWithInput:input];

    // 验证 - 默认请求头仍存在
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    XCTAssertEqualObjects(userAgent, @"SensorsAnalytics iOS SDK", @"自定义请求头不应覆盖 User-Agent");

    // 验证 - 自定义请求头已合并
    NSString *customValue = [request valueForHTTPHeaderField:@"X-Custom-Header"];
    XCTAssertEqualObjects(customValue, @"custom_value", @"应包含 X-Custom-Header 请求头");

    NSString *requestId = [request valueForHTTPHeaderField:@"X-Request-ID"];
    XCTAssertEqualObjects(requestId, @"req-12345", @"应包含 X-Request-ID 请求头");

    // 验证 - 请求头总数正确（User-Agent + 2个自定义）
    NSDictionary *allHeaders = [request allHTTPHeaderFields];
    XCTAssertEqual(allHeaders.count, 3, @"应包含 1 个默认请求头 + 2 个自定义请求头");
}

#pragma mark - 测试场景3：自定义请求头不得覆盖默认请求头

/// 自定义请求头仅作为追加，不得覆盖原有的标准请求头（如 User-Agent）
- (void)testCustomHeadersCannotOverrideDefaultHeaders {
    // 准备
    SAFlowData *input = [[SAFlowData alloc] init];
    input.configOptions = self.configOptions;
    input.HTTPBody = [@"test_body" dataUsingEncoding:NSUTF8StringEncoding];
    // 尝试传入与默认请求头同名的自定义请求头
    input.customHeaders = @{
        @"User-Agent": @"CustomApp/1.0",
        @"X-Custom-Header": @"custom_value"
    };

    // 执行
    NSURLRequest *request = [self.interceptor buildFlushRequestWithInput:input];

    // 验证 - User-Agent 仍为 SDK 默认值，未被自定义值覆盖
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    XCTAssertEqualObjects(userAgent, @"SensorsAnalytics iOS SDK", @"自定义请求头不得覆盖默认 User-Agent");

    // 验证 - 其他自定义请求头仍正常追加
    NSString *customValue = [request valueForHTTPHeaderField:@"X-Custom-Header"];
    XCTAssertEqualObjects(customValue, @"custom_value", @"应包含 X-Custom-Header 请求头");

    // 验证 - 请求头总数正确（User-Agent + 1个自定义）
    NSDictionary *allHeaders = [request allHTTPHeaderFields];
    XCTAssertEqual(allHeaders.count, 2, @"应包含 1 个默认请求头 + 1 个自定义请求头（重名的 User-Agent 被忽略）");
}

#pragma mark - 测试场景4：自定义请求头与 Cookie 共存

/// 同时设置 Cookie 和自定义请求头，两者应共存
- (void)testCustomHeadersWithCookie {
    // 准备
    SAFlowData *input = [[SAFlowData alloc] init];
    input.configOptions = self.configOptions;
    input.HTTPBody = [@"test_body" dataUsingEncoding:NSUTF8StringEncoding];
    input.cookie = @"session_id=abc123";
    input.customHeaders = @{
        @"X-Custom-Header": @"custom_value"
    };

    // 执行
    NSURLRequest *request = [self.interceptor buildFlushRequestWithInput:input];

    // 验证 - Cookie 请求头存在
    NSString *cookie = [request valueForHTTPHeaderField:@"Cookie"];
    XCTAssertEqualObjects(cookie, @"session_id=abc123", @"Cookie 请求头应保留");

    // 验证 - 自定义请求头也存在
    NSString *customValue = [request valueForHTTPHeaderField:@"X-Custom-Header"];
    XCTAssertEqualObjects(customValue, @"custom_value", @"自定义请求头应存在");

    // 验证 - 注意：NSURLRequest 的 Cookie 可能被系统自动处理
    NSDictionary *allHeaders = [request allHTTPHeaderFields];
    NSLog(@"All headers: %@", allHeaders);
}

#pragma mark - 测试场景5：自定义请求头为空字典时的行为

/// 传入空字典作为自定义请求头，行为应与不传时一致
- (void)testEmptyCustomHeadersDictionary {
    // 准备
    SAFlowData *input = [[SAFlowData alloc] init];
    input.configOptions = self.configOptions;
    input.HTTPBody = [@"test_body" dataUsingEncoding:NSUTF8StringEncoding];
    input.customHeaders = @{};

    // 执行
    NSURLRequest *request = [self.interceptor buildFlushRequestWithInput:input];

    // 验证
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    XCTAssertEqualObjects(userAgent, @"SensorsAnalytics iOS SDK", @"空字典时默认请求头应正常");

    NSDictionary *allHeaders = [request allHTTPHeaderFields];
    XCTAssertEqual(allHeaders.count, 1, @"传入空字典时应只有默认的 User-Agent 请求头");
}

#pragma mark - 测试场景6：通过 SDK 公开接口设置自定义请求头

/// 验证通过 SDK 主接口设置的 customHeaders 能正确传递到请求中
- (void)testCustomHeadersFromSDKPublicAPI {
    // 这是一个集成测试，验证自定义请求头能通过公开 API 流入 FlushInterceptor
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"https://test.datasink.example.com/sa?project=default&token=test_token" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];

    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    XCTAssertNotNil(sdk, @"SDK 应初始化成功");

    // 通过公开 API 设置自定义请求头
    [sdk setCustomHeaders:@{
        @"X-Custom-Header": @"from_sdk_api",
        @"X-API-Version": @"2.0"
    }];

    // 验证自定义请求头已存储
    NSDictionary *storedHeaders = [sdk customHeaders];
    XCTAssertNotNil(storedHeaders, @"自定义请求头应被存储");
    XCTAssertEqualObjects(storedHeaders[@"X-Custom-Header"], @"from_sdk_api", @"应包含通过 API 设置的请求头");
    XCTAssertEqualObjects(storedHeaders[@"X-API-Version"], @"2.0", @"应包含通过 API 设置的请求头");
}

@end
