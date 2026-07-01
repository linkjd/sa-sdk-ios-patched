//
// SASM3.c
// SensorsAnalyticsSDK
//
// [自定义修改] SM3 国密哈希算法实现
// 参考标准：GM/T 0004-2012《SM3密码杂凑算法》
//

#include "SASM3.h"

// [自定义修改] SM3 常量
#define SM3_T0 0x79CC4519
#define SM3_T1 0x7A879D8A

// [自定义修改] 循环左移
#define ROTL(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

// [自定义修改] 布尔函数 FF（j < 16）
#define FF0(x, y, z) ((x) ^ (y) ^ (z))

// [自定义修改] 布尔函数 FF（j >= 16）
#define FF1(x, y, z) (((x) & (y)) | ((x) & (z)) | ((y) & (z)))

// [自定义修改] 布尔函数 GG（j < 16）
#define GG0(x, y, z) ((x) ^ (y) ^ (z))

// [自定义修改] 布尔函数 GG（j >= 16）
#define GG1(x, y, z) (((x) & (y)) | ((~(x)) & (z)))

// [自定义修改] 置换函数 P0
#define P0(x) ((x) ^ ROTL((x), 9) ^ ROTL((x), 17))

// [自定义修改] 置换函数 P1
#define P1(x) ((x) ^ ROTL((x), 15) ^ ROTL((x), 23))

// [自定义修改] 字节序转换（大端转小端）
static inline uint32_t sa_sm3_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

// [自定义修改] 小端转大端字节序
static inline void sa_sm3_put_be32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)v;
}

// [自定义修改] SM3 压缩函数
static void sa_sm3_compress(SASM3Context *ctx, const uint8_t block[64]) {
    uint32_t W[68];
    uint32_t W1[64];
    uint32_t A, B, C, D, E, F, G, H;
    uint32_t SS1, SS2, TT1, TT2;
    int j;
    
    // 消息扩展
    for (j = 0; j < 16; j++) {
        W[j] = sa_sm3_be32(block + j * 4);
    }
    for (j = 16; j < 68; j++) {
        W[j] = P1(W[j-16] ^ W[j-9] ^ ROTL(W[j-3], 15)) ^ ROTL(W[j-13], 7) ^ W[j-6];
    }
    for (j = 0; j < 64; j++) {
        W1[j] = W[j] ^ W[j+4];
    }
    
    // 压缩
    A = ctx->state[0];
    B = ctx->state[1];
    C = ctx->state[2];
    D = ctx->state[3];
    E = ctx->state[4];
    F = ctx->state[5];
    G = ctx->state[6];
    H = ctx->state[7];
    
    for (j = 0; j < 16; j++) {
        SS1 = ROTL(ROTL(A, 12) + E + ROTL(SM3_T0, j), 7);
        SS2 = SS1 ^ ROTL(A, 12);
        TT1 = FF0(A, B, C) + D + SS2 + W1[j];
        TT2 = GG0(E, F, G) + H + SS1 + W[j];
        D = C;
        C = ROTL(B, 9);
        B = A;
        A = TT1;
        H = G;
        G = ROTL(F, 19);
        F = E;
        E = P0(TT2);
    }
    
    for (j = 16; j < 64; j++) {
        SS1 = ROTL(ROTL(A, 12) + E + ROTL(SM3_T1, j % 32), 7);
        SS2 = SS1 ^ ROTL(A, 12);
        TT1 = FF1(A, B, C) + D + SS2 + W1[j];
        TT2 = GG1(E, F, G) + H + SS1 + W[j];
        D = C;
        C = ROTL(B, 9);
        B = A;
        A = TT1;
        H = G;
        G = ROTL(F, 19);
        F = E;
        E = P0(TT2);
    }
    
    ctx->state[0] ^= A;
    ctx->state[1] ^= B;
    ctx->state[2] ^= C;
    ctx->state[3] ^= D;
    ctx->state[4] ^= E;
    ctx->state[5] ^= F;
    ctx->state[6] ^= G;
    ctx->state[7] ^= H;
}

// [自定义修改] 初始化 SM3 上下文
void sa_sm3_init(SASM3Context *ctx) {
    ctx->state[0] = 0x7380166F;
    ctx->state[1] = 0x4914B2B9;
    ctx->state[2] = 0x172442D7;
    ctx->state[3] = 0xDA8A0600;
    ctx->state[4] = 0xA96F30BC;
    ctx->state[5] = 0x163138AA;
    ctx->state[6] = 0xE38DEE4D;
    ctx->state[7] = 0xB0FB0E4E;
    ctx->bitlen = 0;
    ctx->buflen = 0;
}

// [自定义修改] 更新 SM3 数据
void sa_sm3_update(SASM3Context *ctx, const uint8_t *data, size_t len) {
    size_t fill;
    
    if (len == 0) return;
    
    ctx->bitlen += len * 8;
    
    // 如果缓冲区有数据，先填充
    if (ctx->buflen > 0) {
        fill = 64 - ctx->buflen;
        if (len < fill) {
            memcpy(ctx->buffer + ctx->buflen, data, len);
            ctx->buflen += len;
            return;
        }
        memcpy(ctx->buffer + ctx->buflen, data, fill);
        sa_sm3_compress(ctx, ctx->buffer);
        data += fill;
        len -= fill;
        ctx->buflen = 0;
    }
    
    // 处理完整块
    while (len >= 64) {
        sa_sm3_compress(ctx, data);
        data += 64;
        len -= 64;
    }
    
    // 保存剩余数据
    if (len > 0) {
        memcpy(ctx->buffer, data, len);
        ctx->buflen = len;
    }
}

// [自定义修改] 完成 SM3 计算
void sa_sm3_final(SASM3Context *ctx, uint8_t digest[SM3_DIGEST_LENGTH]) {
    uint8_t padding[64];
    uint64_t bitlen = ctx->bitlen;
    size_t padlen;
    int i;
    
    // 填充
    padlen = (ctx->buflen < 56) ? (56 - ctx->buflen) : (120 - ctx->buflen);
    memset(padding, 0, sizeof(padding));
    padding[0] = 0x80;
    
    sa_sm3_update(ctx, padding, padlen);
    
    // 添加长度（大端）
    for (i = 0; i < 8; i++) {
        padding[i] = (uint8_t)(bitlen >> (56 - i * 8));
    }
    sa_sm3_update(ctx, padding, 8);
    
    // 输出结果
    for (i = 0; i < 8; i++) {
        sa_sm3_put_be32(digest + i * 4, ctx->state[i]);
    }
}

// [自定义修改] 便捷方法：直接计算数据的 SM3 哈希
void sa_sm3_hash(const uint8_t *data, size_t len, uint8_t digest[SM3_DIGEST_LENGTH]) {
    SASM3Context ctx;
    sa_sm3_init(&ctx);
    sa_sm3_update(&ctx, data, len);
    sa_sm3_final(&ctx, digest);
}
