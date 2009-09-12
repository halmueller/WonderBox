/*
 *  WBDigestFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
@header WBDigestFunctions.h
 @abstract Wrapper on libSystem digest functions. Does not requires Security Frameworks.
 */

#if !defined(__WBDIGEST_FUNCTIONS_H)
#define __WBDIGEST_FUNCTIONS_H 1

typedef struct _WBDigestContext {
  char opaque[240];
} WBDigestContext;

enum {
  kWBDigestUndefined = 0,
  kWBDigestMD2,
  kWBDigestMD4,
  kWBDigestMD5,
  kWBDigestSHA1,
  kWBDigestSHA224,
  kWBDigestSHA256,
  kWBDigestSHA384,
  kWBDigestSHA512,
};
typedef UInt32 WBDigestAlgorithm;

/* Macro for static stack array creation (digest length in bytes) */
#define WB_MD2_DIGEST_LENGTH    16
#define WB_MD4_DIGEST_LENGTH    16
#define WB_MD5_DIGEST_LENGTH    16
#define WB_SHA1_DIGEST_LENGTH   20
#define WB_SHA224_DIGEST_LENGTH 28
#define WB_SHA256_DIGEST_LENGTH 32
#define WB_SHA384_DIGEST_LENGTH 48
#define WB_SHA512_DIGEST_LENGTH 64

#define WB_DIGEST_MAX_LENGTH WB_SHA512_DIGEST_LENGTH

WB_EXPORT
size_t WBDigestGetLengthForAlgorithm(WBDigestAlgorithm algo);

WB_EXPORT
WBDigestAlgorithm WBDigestGetAlgorithmByName(const char *name);

WB_EXPORT // CSSM Bridge
uint32_t WBDigestCSSMAlgorithmForDigest(WBDigestAlgorithm algo);

WB_EXPORT
int WBDigestInit(WBDigestContext *ctxt, WBDigestAlgorithm algo);
WB_EXPORT
int WBDigestUpdate(WBDigestContext *ctxt, const void *data, size_t len);
/*!
@function
 @result Returns the digest length on success, 0 if an error occured 
 */
WB_EXPORT
int WBDigestFinal(unsigned char *md, WBDigestContext *ctxt);

/* Context Properties */
WB_EXPORT
size_t WBDigestContextGetLength(WBDigestContext *ctxt);
WB_EXPORT
const char *WBDigestContextGetName(WBDigestContext *ctxt);
WB_EXPORT
WBDigestAlgorithm WBDigestContextGetAlgorithm(WBDigestContext *ctxt);

/* convenient functions */
WB_EXPORT
int WBDigestFile(const char *path, WBDigestAlgorithm algo, unsigned char *md);
WB_EXPORT
int WBDigestData(const void *data, size_t length, WBDigestAlgorithm algo, unsigned char *md);

#endif /* __WBDIGEST_FUNCTIONS_H */
