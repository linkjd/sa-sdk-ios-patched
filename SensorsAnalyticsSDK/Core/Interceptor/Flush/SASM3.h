//
// SASM3.h
// SensorsAnalyticsSDK
//
// [自定义修改] SM3 国密哈希算法实现
// 参考标准：GM/T 0004-2012《SM3密码杂凑算法》
//

#ifndef SASM3_h
#define SASM3_h

#include <stdio.h>
#include <stdint.h>
#include <string.h>

// SM3 哈希结果长度（字节）
#define SM3_DIGEST_LENGTH 32

// SM3 上下文结构
typedef struct {
    uint32_t state[8];
    uint64_t bitlen;
    uint8_t buffer[64];
    uint32_t buflen;
} SASM3Context;

// [自定义修改] 初始化 SM3 上下文
void sa_sm3_init(SASM3Context *ctx);

// [自定义修改] 更新 SM3 数据
void sa_sm3_update(SASM3Context *ctx, const uint8_t *data, size_t len);

// [自定义修改] 完成 SM3 计算，输出哈希结果
void sa_sm3_final(SASM3Context *ctx, uint8_t digest[SM3_DIGEST_LENGTH]);

// [自定义修改] 便捷方法：直接计算数据的 SM3 哈希
void sa_sm3_hash(const uint8_t *data, size_t len, uint8_t digest[SM3_DIGEST_LENGTH]);

#endif /* SASM3_h */
