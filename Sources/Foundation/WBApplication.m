/*
 *  WBApplication.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBApplication.h>

#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBLSFunctions.h>
#import <WonderBox/WBProcessFunctions.h>

enum {
  kWBUndefinedSignature = kUnknownType // '????'
};

@implementation WBApplication {
@private
  NSString *wb_name;
  OSType wb_signature;
  NSString *wb_identifier;
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBApplication *copy = [[[self class] allocWithZone:zone] init];
  copy->wb_name = [wb_name copyWithZone:zone];
  copy->wb_signature = wb_signature;
  copy->wb_identifier = [wb_identifier copyWithZone:zone];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeInteger:wb_signature forKey:@"WBSignature"];
  if (wb_name) [coder encodeObject:wb_name forKey:@"WBName"];
  if (wb_identifier) [coder encodeObject:wb_identifier forKey:@"WBIdentifier"];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    wb_signature = (OSType)[coder decodeIntegerForKey:@"WBSignature"];
    wb_name = [[coder decodeObjectForKey:@"WBName"] retain];
    wb_identifier = [[coder decodeObjectForKey:@"WBIdentifier"] retain];
  }
  return self;
}

#pragma mark -
+ (NSArray *)runningApplication:(BOOL)onlyVisible {
  NSMutableArray *apps = [[NSMutableArray alloc] init];
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  while (procNotFound != GetNextProcess(&psn))  {
    /* If should include background only, or if is not background only */
    if (!onlyVisible || !WBProcessIsBackgroundOnly(&psn)) {
      WBApplication *app = [[WBApplication alloc] initWithProcessSerialNumber:&psn];
      if (app) {
        [apps addObject:app];
        [app release];
      }
    }
  }
  return [apps autorelease];
}

#pragma mark Convenient initializer
+ (id)applicationWithPath:(NSString *)path {
  return [[[self alloc] initWithPath:path] autorelease];
}

+ (id)applicationWithProcessSerialNumber:(ProcessSerialNumber *)psn {
  return [[[self alloc] initWithProcessSerialNumber:psn] autorelease];
}

+ (id)applicationWithName:(NSString *)name {
  return [[[self alloc] initWithName:name] autorelease];
}

+ (id)applicationWithName:(NSString *)name signature:(OSType)aSignature {
  return [[[self alloc] initWithName:name signature:aSignature] autorelease];
}
+ (id)applicationWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier {
  return [[[self alloc] initWithName:name bundleIdentifier:anIdentifier] autorelease];
}


#pragma mark -
- (id)initWithPath:(NSString *)path {
  if (!path) {
    [self release];
    return nil;
  }

  if (self = [super init]) {
    if (![self setPath:path]) {
      [self release];
      self = nil;
    }
  }

  return self;
}

- (id)initWithProcessSerialNumber:(ProcessSerialNumber *)psn {
  CFDictionaryRef info = ProcessInformationCopyDictionary(psn, kProcessDictionaryIncludeAllInformationMask);
  if (info) {
    /* Get name */
    CFStringRef name = CFDictionaryGetValue(info, kCFBundleNameKey);
    CFStringRef bundle = CFDictionaryGetValue(info, kCFBundleIdentifierKey);

    CFStringRef creator = CFDictionaryGetValue(info, CFSTR("FileCreator"));
    OSType signature = creator ? WBGetOSTypeFromString(creator) : kWBUndefinedSignature;
    self = [self initWithName:(NSString *)name signature:signature bundleIdentifier:(NSString *)bundle];

    CFRelease(info);
  } else {
    [self release];
    self = nil;
  }
  return self;
}

- (id)initWithName:(NSString *)name {
  if (self = [super init]) {
    [self setName:name];
  }
  return self;
}

- (id)initWithName:(NSString *)name signature:(OSType)aSignature {
  return [self initWithName:name signature:aSignature bundleIdentifier:nil];
}
- (id)initWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier {
  return [self initWithName:name signature:kLSUnknownCreator bundleIdentifier:anIdentifier];
}
- (id)initWithName:(NSString *)name signature:(OSType)aSignature bundleIdentifier:(NSString *)anIdentifier {
  if (self = [super init]) {
    [self setSignature:aSignature bundleIdentifier:anIdentifier];
  }
  return self;
}

- (void)dealloc {
  [wb_name release];
  [wb_identifier release];
  spx_dealloc();
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {name='%@' signature='%@' identifier='%@'}",
    [self class], self,
    wb_name, WBStringForOSType(wb_signature), wb_identifier];
}

static NSString * const kInvalidIdentifier = @"org.shadowlab.__invalid__";

WB_INLINE
bool __IsValidSignature(OSType signature) {
  return signature && signature != kWBUndefinedSignature;
}
WB_INLINE
bool __IsValidIdentifier(id identifier) {
  return identifier && identifier != kInvalidIdentifier;
}

- (NSUInteger)hash {
  OSType type = [self signature];
  NSString *bundle = [self bundleIdentifier];
  return [bundle hash] ^ type;
}

- (BOOL)isEqual:(id)object {
  if (self == object) return YES;

  if (![object isKindOfClass:[WBApplication class]]) return NO;

  if ([self signature]) {
    if (![object signature] || [object signature] != wb_signature) return NO;
  } else if ([object signature]) return NO;

  if ([self bundleIdentifier]) {
    if (![object bundleIdentifier] || ![wb_identifier isEqualToString:[object bundleIdentifier]]) return NO;
  } else if ([object bundleIdentifier]) return NO;

  return YES;
}

#pragma mark -
- (NSString *)name {
  if (!wb_name) {
    NSString *path = [self path];
    if (path) {
      /* Extract name from last path component */
      wb_name = [[[[NSFileManager defaultManager] displayNameAtPath:path] stringByDeletingPathExtension] copy];
    }
  }
  return wb_name;
}

- (void)setName:(NSString *)newName {
  SPXSetterCopy(wb_name, newName);
}

- (OSType)signature {
  if (!wb_signature) {
    NSString *path = [self path];
    if (path) {
      wb_signature = WBLSGetSignatureForPath(SPXNSToCFString(path));
    }
    if (!wb_signature) wb_signature = kWBUndefinedSignature;
  }
  return (__IsValidSignature(wb_signature)) ? wb_signature : kLSUnknownCreator;
}
- (void)setSignature:(OSType)signature {
  [self setSignature:signature bundleIdentifier:nil];
}

- (NSString *)bundleIdentifier {
  if (!wb_identifier) {
    NSString *path = [self path];
    if (path) {
      wb_identifier = (id)WBLSCopyBundleIdentifierForPath((CFStringRef)path);
    }
    if (!wb_identifier) wb_identifier = kInvalidIdentifier;
  }
  return (__IsValidIdentifier(wb_identifier)) ? wb_identifier : nil;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  [self setSignature:kLSUnknownCreator bundleIdentifier:identifier];
}

- (void)setSignature:(OSType)aSignature bundleIdentifier:(NSString *)identifier {
  // Should we invalidate the name ?
  wb_signature = aSignature;
  SPXSetterCopy(wb_identifier, identifier);
}

#pragma mark -
- (BOOL)isValid {
  return __IsValidSignature(wb_signature) || __IsValidIdentifier(wb_identifier);
}
- (NSImage *)icon {
  NSString *path = [self path];
  return path ? [[NSWorkspace sharedWorkspace] iconForFile:path] : nil;
}

- (NSString *)path {
  NSString *path = nil;
  if (__IsValidIdentifier(wb_identifier))
    path = WBLSFindApplicationForBundleIdentifier(wb_identifier);

  if (!path && __IsValidSignature(wb_signature))
    path = WBLSFindApplicationForSignature(wb_signature);

  return path;
}
- (BOOL)setPath:(NSString *)aPath {
  /* Reset name */
  [self setName:nil];

  if (!aPath) {
    [self setSignature:kLSUnknownCreator bundleIdentifier:nil];
    return YES;
  }

  Boolean isApp = false;
  if (noErr != WBLSIsApplicationAtPath(SPXNSToCFString(aPath), &isApp) || !isApp) {
    return NO;
  }

  CFStringRef bundle = WBLSCopyBundleIdentifierForPath(SPXNSToCFString(aPath));
  OSType signature = WBLSGetSignatureForPath(SPXNSToCFString(aPath)) ? : kWBUndefinedSignature;
  [self setSignature:signature bundleIdentifier:SPXCFToNSString(bundle)];
  SPXCFRelease(bundle);

  return [self isValid];
}

- (BOOL)getFSRef:(FSRef *)ref {
  NSParameterAssert(ref);

  BOOL ok = NO;
  if (__IsValidIdentifier(wb_identifier))
    ok = noErr == WBLSGetApplicationForBundleIdentifier(SPXNSToCFString(wb_identifier), ref);

  if (!ok && __IsValidSignature(wb_signature))
    ok = noErr == WBLSGetApplicationForSignature(wb_signature, ref);

  return ok;
}

- (ProcessSerialNumber)process {
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};

  if (__IsValidIdentifier(wb_identifier))
    psn = WBProcessGetProcessWithBundleIdentifier(SPXNSToCFString(wb_identifier));

  if (psn.lowLongOfPSN == kNoProcess && __IsValidSignature(wb_signature))
    psn = WBProcessGetProcessWithSignature(wb_signature);

  return psn;
}

- (BOOL)launch {
  return [[NSWorkspace sharedWorkspace] launchApplication:[self path]];
}

- (BOOL)isFront {
  ProcessSerialNumber front;
  if (noErr == GetFrontProcess(&front)) {
    ProcessSerialNumber psn = [self process];
    if ((kNoProcess != psn.lowLongOfPSN) || (kNoProcess != psn.highLongOfPSN)) {
      Boolean isSame = false;
      return (noErr == SameProcess(&psn, &front, &isSame)) && isSame;
    }
  }
  return NO;
}

- (BOOL)isRunning {
  ProcessSerialNumber psn = [self process];
  return (kNoProcess != psn.lowLongOfPSN) || (kNoProcess != psn.highLongOfPSN);
}

@end

