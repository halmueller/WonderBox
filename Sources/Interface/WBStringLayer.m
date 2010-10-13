/*
 *  WBStringLayer.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBStringLayer.h)

@interface WBStringLayer ()
- (NSLayoutManager *)layoutManager;
- (NSTextContainer *)textContainer;
- (id)initWithSize:(NSSize)aSize textStorage:(NSTextStorage *)aStorage;
@end

@implementation WBStringLayer

- (id)initWithSize:(NSSize)aSize {
  return [self initWithSize:aSize textStorage:nil];
}

- (id)initWithSize:(NSSize)aSize textStorage:(NSTextStorage *)aStorage {
  if (self = [super initWithSize:aSize]) {
    wb_manager = [[NSLayoutManager alloc] init];
    wb_container = [[NSTextContainer alloc] initWithContainerSize:aSize];
    [wb_manager addTextContainer:wb_container];
    [wb_container release];

    NSTextStorage *storage = aStorage ? [aStorage retain] : [[NSTextStorage alloc] init];
    [storage addLayoutManager:wb_manager];
    [wb_manager release];

    [self setTextStorage:storage];
    [storage release];
  }
  return self;
}

- (id)initWithSize:(NSSize)aSize attributedString:(NSAttributedString *)aString {
  return [self initWithSize:aSize textStorage:aString ? [[[NSTextStorage alloc] initWithAttributedString:aString] autorelease] : nil];
}

- (id)initWithSize:(NSSize)aSize string:(NSString *)aString attributes:(NSDictionary *)attributes {
  return [self initWithSize:aSize textStorage:aString ? [[[NSTextStorage alloc] initWithString:aString
                                                                                    attributes:attributes] autorelease] : nil];
}

- (void)dealloc {
  [wb_storage release];
  [super dealloc];
}

#pragma mark -
- (BOOL)wraps {
  return !wb_slFlags.clip;
}
- (void)setWraps:(BOOL)wrap {
  BOOL previous = WBFlagTestAndSet(wb_slFlags.clip, !wrap);
  if (wb_slFlags.clip != previous) {
    if (wb_slFlags.clip)
      [[self textContainer] setContainerSize:NSMakeSize(64000, 64000)];
    [self setNeedsUpdate:YES];
  }
}

- (NSTextStorage *)storage {
  return wb_storage;
}
- (void)setTextStorage:(NSTextStorage *)aStorage {
  WBSetterRetain(wb_storage, aStorage);
}

- (NSTextContainer *)textContainer {
  return wb_container;
}
- (NSLayoutManager *)layoutManager {
  return wb_manager;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
  [wb_storage setAttributedString:attributedString];
  [self setNeedsUpdate:YES];
}
- (void)setString:(NSString *)aString attributes:(NSDictionary *)attribs {
  if (!attribs) attribs = [wb_storage attributesAtIndex:0 effectiveRange:nil];
  NSAttributedString *astr = [[NSAttributedString alloc] initWithString:aString attributes:attribs];
  [self setAttributedString:astr];
  [astr release];
}

#pragma mark -
- (BOOL)isMultipleThreadsEnabled {
return [wb_manager backgroundLayoutEnabled];
}
- (void)setMultipleThreadsEnabled:(BOOL)threadSafe {
  [wb_manager setBackgroundLayoutEnabled:!threadSafe];
}

#pragma mark -
- (NSRect)wb_textBounds {
  NSLayoutManager *layout = [self layoutManager];
  NSTextContainer *container = [self textContainer];
  /* generate glyphs */
  if ([layout respondsToSelector:@selector(ensureLayoutForTextContainer:)])
    [layout ensureLayoutForTextContainer:container];
  else
    [layout boundingRectForGlyphRange:[layout glyphRangeForTextContainer:container]
                      inTextContainer:container];

  /* returns used size */
  return [layout usedRectForTextContainer:container];
}
- (NSSize)drawingSizeForSize:(NSSize)aSize {
  if (!wb_slFlags.clip)
    [[self textContainer] setContainerSize:aSize];
  return [self wb_textBounds].size;
}

- (void)drawContentInRect:(NSRect)aRect {
  NSLayoutManager *layout = [self layoutManager];
  NSTextContainer *container = [self textContainer];

  NSRect tbounds = [self wb_textBounds];
  NSPoint orig = NSMakePoint(aRect.origin.x - tbounds.origin.x, aRect.origin.y - tbounds.origin.y);
  //[layout drawBackgroundForGlyphRange:[layout glyphRangeForTextContainer:container] atPoint:orig];
  [layout drawGlyphsForGlyphRange:[layout glyphRangeForTextContainer:container] atPoint:orig];
}

@end
