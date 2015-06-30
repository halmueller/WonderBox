/*
 *  WBBezelItemContent.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

WB_OBJC_EXPORT
@interface WBBezelItemContent : NSView {
}
- (id)initWithContent:(id)content;

- (id)content;

- (NSSize)size;

@end
