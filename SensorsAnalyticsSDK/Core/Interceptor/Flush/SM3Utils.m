/**
 * SM3 国密哈希算法 — Objective-C 实现
 * 纯原生代码（C + Foundation），零外部依赖
 */

#import "SM3Utils.h"
#import <CommonCrypto/CommonDigest.h>

#pragma mark - SM3 核心 C 实现

// SM3 初始值 IV
static const uint32_t SM3_IV[8] = {
    0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
    0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e
};

// 常量 T
static uint32_t SM3_T(int j) {
    return (j < 16) ? 0x79cc4519 : 0x7a879d8a;
}

// 循环左移
static inline uint32_t rotl32(uint32_t x, int n) {
    return (x << n) | (x >> (32 - n));
}

// 布尔函数 FF
static inline uint32_t FF(int j, uint32_t X, uint32_t Y, uint32_t Z) {
    if (j < 16) return X ^ Y ^ Z;
    return (X & Y) | (X & Z) | (Y & Z);
}

// 布尔函数 GG
static inline uint32_t GG(int j, uint32_t X, uint32_t Y, uint32_t Z) {
    if (j < 16) return X ^ Y ^ Z;
    return (X & Y) | (~X & Z);
}

// 置换函数 P0
static inline uint32_t P0(uint32_t X) {
    return X ^ rotl32(X, 9) ^ rotl32(X, 17);
}

// 置换函数 P1
static inline uint32_t P1(uint32_t X) {
    return X ^ rotl32(X, 15) ^ rotl32(X, 23);
}

/**
 * 压缩函数 CF
 * @param V  256 位输入（8 个 uint32_t，将被原地更新）
 * @param B  512 位消息块（16 个 uint32_t）
 */
static void SM3_CF(uint32_t V[8], const uint32_t B[16]) {
    uint32_t W[68];
    uint32_t W1[64];

    // 消息扩展
    for (int i = 0; i < 16; i++) {
        W[i] = B[i];
    }
    for (int j = 16; j < 68; j++) {
        W[j] = P1(W[j - 16] ^ W[j - 9] ^ rotl32(W[j - 3], 15))
             ^ rotl32(W[j - 13], 7) ^ W[j - 6];
    }
    for (int j = 0; j < 64; j++) {
        W1[j] = W[j] ^ W[j + 4];
    }

    // 压缩迭代
    uint32_t A = V[0], Bv = V[1], C = V[2], D = V[3];
    uint32_t E = V[4], F = V[5], G = V[6], Hv = V[7];

    for (int j = 0; j < 64; j++) {
        uint32_t Tj = SM3_T(j);
        uint32_t SS1 = rotl32(rotl32(A, 12) + E + rotl32(Tj, j), 7);
        uint32_t SS2 = SS1 ^ rotl32(A, 12);
        uint32_t TT1 = FF(j, A, Bv, C) + D + SS2 + W1[j];
        uint32_t TT2 = GG(j, E, F, G) + Hv + SS1 + W[j];

        D = C;
        C = rotl32(Bv, 9);
        Bv = A;
        A = TT1;
        Hv = G;
        G = rotl32(F, 19);
        F = E;
        E = P0(TT2);
    }

    V[0] ^= A;
    V[1] ^= Bv;
    V[2] ^= C;
    V[3] ^= D;
    V[4] ^= E;
    V[5] ^= F;
    V[6] ^= G;
    V[7] ^= Hv;
}

/**
 * 从字节数组按大端序读取 uint32_t
 */
static inline uint32_t readBE32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16)
         | ((uint32_t)p[2] << 8)  |  (uint32_t)p[3];
}

/**
 * 将 uint32_t 按大端序写入字节数组
 */
static inline void writeBE32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)(v);
}

/**
 * SM3 哈希计算
 * @param msg   输入消息
 * @param len   消息长度（字节）
 * @param hash  输出 32 字节摘要（由调用者分配）
 */
static void SM3_Hash(const uint8_t *msg, size_t len, uint8_t hash[32]) {
    // 计算填充
    size_t bitLen = len * 8;
    size_t padLen = (len % 64 < 56) ? (56 - len % 64) : (120 - len % 64);
    size_t totalLen = len + padLen + 8;

    uint8_t *padded = (uint8_t *)calloc(totalLen, 1);
    memcpy(padded, msg, len);
    padded[len] = 0x80;

    // 写入 64 位长度（大端序）
    uint64_t bitLen64 = (uint64_t)bitLen;
    for (int i = 0; i < 8; i++) {
        padded[totalLen - 8 + i] = (uint8_t)(bitLen64 >> (56 - i * 8));
    }

    // 初始化 V
    uint32_t V[8];
    memcpy(V, SM3_IV, sizeof(SM3_IV));

    // 逐块压缩
    for (size_t offset = 0; offset < totalLen; offset += 64) {
        uint32_t B[16];
        for (int i = 0; i < 16; i++) {
            B[i] = readBE32(padded + offset + i * 4);
        }
        SM3_CF(V, B);
    }

    free(padded);

    // 输出
    for (int i = 0; i < 8; i++) {
        writeBE32(hash + i * 4, V[i]);
    }
}

/**
 * HMAC-SM3 核心
 */
static void SM3_HMAC(const uint8_t *key, size_t keyLen,
                     const uint8_t *data, size_t dataLen,
                     uint8_t output[32]) {
    const size_t blockSize = 64;
    uint8_t k0[64] = {0};

    if (keyLen > blockSize) {
        SM3_Hash(key, keyLen, k0);
        memset(k0 + 32, 0, 32);  // 补零到 64
    } else {
        memcpy(k0, key, keyLen);
    }

    uint8_t ipad[64], opad[64];
    for (int i = 0; i < 64; i++) {
        ipad[i] = k0[i] ^ 0x36;
        opad[i] = k0[i] ^ 0x5c;
    }

    // 内层
    uint8_t *innerMsg = (uint8_t *)malloc(blockSize + dataLen);
    memcpy(innerMsg, ipad, blockSize);
    memcpy(innerMsg + blockSize, data, dataLen);
    uint8_t innerHash[32];
    SM3_Hash(innerMsg, blockSize + dataLen, innerHash);
    free(innerMsg);

    // 外层
    uint8_t outerMsg[blockSize + 32];
    memcpy(outerMsg, opad, blockSize);
    memcpy(outerMsg + blockSize, innerHash, 32);
    SM3_Hash(outerMsg, blockSize + 32, output);
}

#pragma mark - SM3Utils 实现

@implementation SM3Utils

+ (NSData *)sm3WithDataChunks:(NSArray<NSData *> *)dataChunks {
    // 计算总长度并拼接
    size_t totalLen = 0;
    for (NSData *chunk in dataChunks) {
        totalLen += chunk.length;
    }
    uint8_t *msg = (uint8_t *)malloc(totalLen);
    size_t offset = 0;
    for (NSData *chunk in dataChunks) {
        memcpy(msg + offset, chunk.bytes, chunk.length);
        offset += chunk.length;
    }

    uint8_t hash[32];
    SM3_Hash(msg, totalLen, hash);
    free(msg);

    return [NSData dataWithBytes:hash length:32];
}

+ (NSString *)sm3HexWithDataChunks:(NSArray<NSData *> *)dataChunks {
    NSData *hash = [self sm3WithDataChunks:dataChunks];
    const uint8_t *bytes = hash.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:64];
    for (NSUInteger i = 0; i < hash.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex;
}

+ (NSString *)sm3HexWithString:(NSString *)str {
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [self sm3HexWithData:data];
}

+ (NSString *)sm3HexWithData:(NSData *)data {
    return [self sm3HexWithDataChunks:@[data]];
}

+ (NSData *)hmacSM3WithKey:(NSData *)key dataChunks:(NSArray<NSData *> *)dataChunks {
    // 拼接数据块
    size_t dataLen = 0;
    for (NSData *chunk in dataChunks) {
        dataLen += chunk.length;
    }
    uint8_t *data = (uint8_t *)malloc(dataLen);
    size_t offset = 0;
    for (NSData *chunk in dataChunks) {
        memcpy(data + offset, chunk.bytes, chunk.length);
        offset += chunk.length;
    }

    uint8_t output[32];
    SM3_HMAC(key.bytes, key.length, data, dataLen, output);
    free(data);

    return [NSData dataWithBytes:output length:32];
}

+ (NSString *)hmacSM3HexWithKeyData:(NSData *)key data:(NSData *)data {
    NSData *hash = [self hmacSM3WithKey:key dataChunks:@[data]];
    const uint8_t *bytes = hash.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:64];
    for (NSUInteger i = 0; i < hash.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex;
}

+ (NSString *)hmacSM3HexWithKey:(NSString *)key data:(NSString *)data {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *srcData = [data dataUsingEncoding:NSUTF8StringEncoding];
    return [self hmacSM3HexWithKeyData:keyData data:srcData];
}

+ (NSString *)genRandomKeySeed {
    uint8_t keyBytes[64];
    int result = SecRandomCopyBytes(kSecRandomDefault, 64, keyBytes);
    if (result != errSecSuccess) {
        // 回退：使用 arc4random
        for (int i = 0; i < 64; i++) {
            keyBytes[i] = (uint8_t)(arc4random() & 0xFF);
        }
    }
    NSData *keyData = [NSData dataWithBytes:keyBytes length:64];
    return [keyData base64EncodedStringWithOptions:0];
}

@end
