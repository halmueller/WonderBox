/*
 *  WBCGFunctions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#if !defined(__WBCG_FUNCTIONS_H)
#define __WBCG_FUNCTIONS_H 1

#include <ApplicationServices/ApplicationServices.h>

#pragma mark Shapes
WB_EXPORT
void WBCGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius);

WB_EXPORT
void WBCGPathAddRoundRect(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGFloat radius);

WB_EXPORT
void WBCGContextAddRoundRectWithRadius(CGContextRef context, CGRect rect, CGSize radius);

WB_EXPORT
void WBCGPathAddRoundRectWithRadius(CGMutablePathRef path, const CGAffineTransform *transform, CGRect rect, CGSize radius);

WB_EXPORT
void WBCGContextAddStar(CGContextRef ctxt, CGPoint center, CFIndex sides, CGFloat radius, CGFloat internRadius);

WB_EXPORT
void WBCGPathAddStar(CGMutablePathRef path, const CGAffineTransform *transform, CGPoint center, CFIndex sides, CGFloat radius, CGFloat internRadius);

WB_EXPORT
void WBCGContextStrokeWaves(CGContextRef context, CGRect rect, CGFloat period);

/* Helpers */
WB_EXPORT
void WBCGContextStrokeLine(CGContextRef ctxt, CGFloat x, CGFloat y, CGFloat x2, CGFloat y2);

#pragma mark Resolution Independant UI
WB_EXPORT
CGFloat WBCGContextGetUserSpaceScaleFactor(CGContextRef ctxt);
WB_EXPORT
void WBCGContextSetLinePixelWidth(CGContextRef context, CGFloat width);

WB_INLINE
CGRect WBCGContextIntegralPixelRect(CGContextRef aContext, CGRect aRect) {
  aRect = CGContextConvertRectToDeviceSpace(aContext, aRect);
  aRect = CGRectIntegral(aRect);
  return CGContextConvertRectToUserSpace(aContext, aRect);
}

WB_INLINE
CGFloat WBCGPointRoundToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (round(point * factor) + shift) / factor;
}
WB_INLINE
CGFloat WBCGPointFloorToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (floor(point * factor) + shift) / factor;
}
WB_INLINE
CGFloat WBCGPointCeilToPixel(CGFloat point, CGFloat factor, CGFloat shift) {
  return (ceil(point * factor) + shift) / factor;
}

WB_INLINE
CGRect WBCGRectRoundIntegral(CGRect aRect, CGFloat factor) {
  return CGRectMake(round(aRect.origin.x * factor) / factor,
                    round(aRect.origin.y * factor) / factor,
                    round(aRect.size.width * factor) / factor,
                    round(aRect.size.height * factor) / factor);
}

#pragma mark Color Spaces
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateGray(void);
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateRGB(void);
WB_EXPORT
CGColorSpaceRef WBCGColorSpaceCreateCMYK(void);

#pragma mark Color
WB_EXPORT
CGColorRef WBCGColorCreateGray(CGFloat white, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
WB_EXPORT
CGColorRef WBCGColorCreateCMYK(CGFloat cyan, CGFloat magenta, CGFloat yellow, CGFloat black, CGFloat alpha);

#pragma mark Shading
/* All shading functions used rgba color space */
typedef CGFloat (*WBShadingFactorFunction)(CGFloat factor);

WB_EXPORT
CGFloat WBCGShadingSinFactorFunction(CGFloat factor);
WB_EXPORT
CGFloat WBCGShadingCircularFactorFunction(CGFloat factor);

typedef struct _WBCGSimpleShadingInfo {
  CGFloat start[4];
  CGFloat end[4];
  WBShadingFactorFunction fct;
} WBCGSimpleShadingInfo;
WB_EXPORT
void WBCGShadingSimpleShadingFunction(void *pinfo, const CGFloat *in, CGFloat *out);

typedef struct {
  NSUInteger count;
  struct {
    CGFloat end;
    CGFloat rgba[4];
    CGFloat rgba2[4];
    WBShadingFactorFunction fct;
  } steps[];
} WBCGMultiShadingInfo;
WB_EXPORT
void WBCGShadingMultiShadingFunction(void *pinfo, const CGFloat *in, CGFloat *out);

WB_EXPORT
CGShadingRef WBCGShadingCreateAxial(CGPoint start, CGPoint end, CGFunctionEvaluateCallback callback, const void *ctxt);

WB_EXPORT
CGShadingRef WBCGShadingCreateRadial(CGPoint start, CGFloat startr, CGPoint end, CGFloat endr, CGFunctionEvaluateCallback callback, const void *ctxt);

#pragma mark Layer
WB_EXPORT
CGLayerRef WBCGLayerCreateWithContext(CGContextRef ctxt, CGSize size, CFDictionaryRef auxiliaryInfo, bool scaleToUserSpace);

WB_EXPORT
CGLayerRef WBCGLayerCreateWithVerticalShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace,
                                              CGFunctionEvaluateCallback callback, const void *userInfo);
WB_EXPORT
CGLayerRef WBCGLayerCreateWithHorizontalShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace,
                                                CGFunctionEvaluateCallback callback, const void *userInfo);
WB_EXPORT
CGLayerRef WBCGLayerCreateWithAxialShading(CGContextRef ctxt, CGSize size, bool scaleToUserSpace, CGPoint start, CGPoint end,
                                           CGFunctionEvaluateCallback callback, const void *userInfo);

WB_EXPORT
CGImageRef WBCGLayerCreateImage(CGLayerRef layer);

#pragma mark Images
/*!
@param type The UTI (uniform type identifier) of the resulting image file.
 */
WB_EXPORT
bool WBCGImageWriteToURL(CGImageRef image, CFURLRef url, CFStringRef type);
WB_EXPORT
bool WBCGImageWriteToFile(CGImageRef image, CFStringRef file, CFStringRef type);
WB_EXPORT 
CGImageRef WBCGImageCreateFromURL(CFURLRef url, CFDictionaryRef options);

#endif /* __WBCGFUNCTIONS_H */
