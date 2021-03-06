/*
 *  WBComponent.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

WB_OBJC_EXPORT
@interface WBComponent : NSObject <NSCopying> {
@private
  Component _comp;
  ComponentDescription _desc;

  NSImage *_icon;
  NSString *_manu, *_name, *_info, *_cname;
}

#if OBJC_NEW_PROPERTIES
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *manufacturer;
@property(nonatomic, readonly) NSString *informations;
@property(nonatomic, readonly) NSString *componentName;
#endif

+ (NSArray *)componentsWithComponentDescription:(const ComponentDescription *)search;
+ (NSArray *)componentsWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu;

+ (id)componentWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu;
+ (id)componentWithComponentDescription:(const ComponentDescription *)desc;
+ (id)componentWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component;

- (id)initWithComponent:(const Component)comp; // designated
- (id)initWithComponentInstance:(const ComponentInstance)instance;

- (id)initWithComponentDescription:(const ComponentDescription *)desc;
- (id)initWithType:(OSType)aType subtype:(OSType)aSubtype manufactor:(OSType)aManufactor;
- (id)initWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component;

- (NSString *)name;
- (NSString *)manufacturer;
- (NSString *)informations;
- (NSString *)componentName;

- (OSStatus)open:(ComponentInstance *)instance;

- (Component)component;
- (SInt32)resourceVersion:(OSStatus *)error;
- (void)getComponentDescription:(ComponentDescription *)description;

@end
