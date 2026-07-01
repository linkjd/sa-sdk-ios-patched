/**
 * SM3 国密哈希算法 — Objective-C 实现
 * 纯原生代码，零外部依赖，适用于 iOS / macOS
 *
 * 对标 Java 版本的 Sm3Utils 功能：
 *   - sm3 / sm3Hex：纯 SM3 哈希
 *   - hmacSM3 / hmacSM3Hex：带密钥的 HMAC-SM3
 *   - genRandomKeySeed：生成随机密钥
 *
 * 用法：
 *   #import "SM3Utils.h"
 *   NSString *hash = [SM3Utils sm3HexWithString:@"abc"];
 *   NSString *hmac = [SM3Utils hmacSM3HexWithKey:@"key" data:@"data"];
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SM3Utils : NSObject

/// SM3 哈希（多数据块）→ 字节数组
+ (NSData *)sm3WithDataChunks:(NSArray<NSData *> *)dataChunks;

/// SM3 哈希（多数据块）→ 十六进制字符串
+ (NSString *)sm3HexWithDataChunks:(NSArray<NSData *> *)dataChunks;

/// SM3 哈希（单字符串，UTF-8）→ 十六进制
+ (NSString *)sm3HexWithString:(NSString *)str;

/// SM3 哈希（单 NSData）→ 十六进制
+ (NSString *)sm3HexWithData:(NSData *)data;

/// HMAC-SM3 → 字节数组
+ (NSData *)hmacSM3WithKey:(NSData *)key dataChunks:(NSArray<NSData *> *)dataChunks;

/// HMAC-SM3 → 十六进制（字节参数）
+ (NSString *)hmacSM3HexWithKeyData:(NSData *)key data:(NSData *)data;

/// HMAC-SM3 → 十六进制（字符串参数，UTF-8）
+ (NSString *)hmacSM3HexWithKey:(NSString *)key data:(NSString *)data;

/// 生成随机密钥（64 字节随机 → Base64）
+ (NSString *)genRandomKeySeed;

@end

NS_ASSUME_NONNULL_END
