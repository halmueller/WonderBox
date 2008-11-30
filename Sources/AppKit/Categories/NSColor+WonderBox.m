/*
 *  NSColor+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSColor+WonderBox.h)

@implementation NSColor (WBHexdecimal)

+ (id)colorWithDeviceHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha {
  return [self colorWithDeviceRed:red/255. green:green/255. blue:blue/255. alpha:alpha/255.];
}

+ (id)colorWithCalibratedHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha {
  return [self colorWithCalibratedRed:red/255. green:green/255. blue:blue/255. alpha:alpha/255.];
}

@end

#define WBCachedColor(color) { \
  static NSColor *wb_color = nil; \
  if (wb_color) return wb_color; \
  @synchronized(self) { \
    if (!wb_color) { wb_color = [color retain]; } \
  } \
  return wb_color; \
}

@implementation NSColor (WBColorTable)

+ (NSColor *)wbBorderColor {
  WBCachedColor([NSColor colorWithCalibratedWhite:.576 alpha:1]);
}

+ (NSColor *)wbBackgroundColor {
  WBCachedColor([NSColor colorWithCalibratedWhite:.933 alpha:1]);
}

+ (NSColor *)wbLightBorderColor {
  WBCachedColor([NSColor colorWithCalibratedWhite:.698 alpha:1]);
}

+ (NSColor *)wbWindowBackgroundColor {
  WBCachedColor([NSColor colorWithCalibratedWhite:.78 alpha:1]);
}

@end
