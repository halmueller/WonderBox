/*
 *  NSError+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSError+WonderBox.h>

@implementation NSError (WBExtensions)

+ (NSError *)cancel {
  return [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
}

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath {
  return [self fileErrorWithCode:code path:aPath reason:nil];
}
+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath reason:(NSString *)message {
  NSDictionary *info = nil;
  if (aPath)
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            aPath, NSFilePathErrorKey,
            message, NSLocalizedFailureReasonErrorKey, nil];
  else if (message)
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            message, NSLocalizedFailureReasonErrorKey, nil];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL {
  return [self fileErrorWithCode:code url:anURL reason:nil];
}
+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL reason:(NSString *)message {
  NSDictionary *info = nil;
  if (anURL)
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            anURL, NSURLErrorKey,
            message, NSLocalizedFailureReasonErrorKey, nil];
  else if (message)
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            message, NSLocalizedFailureReasonErrorKey, nil];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

+ (id)errorWithDomain:(NSString *)aDomain code:(NSInteger)code reason:(NSString *)message {
  NSDictionary *info = message ? [NSDictionary dictionaryWithObject:message forKey:NSLocalizedFailureReasonErrorKey] : nil;
  return [NSError errorWithDomain:aDomain code:code userInfo:info];
}
+ (id)errorWithDomain:(NSString *)aDomain code:(NSInteger)code format:(NSString *)message, ... {
  va_list args;
  va_start(args, message);
  NSString *str = [[NSString alloc] initWithFormat:message arguments:args];
  va_end(args);
  NSError *error = [NSError errorWithDomain:aDomain code:code reason:str];
  spx_release(str);
  return error;
}

- (BOOL)isCancel {
  /* Cocoa */
  if ([[self domain] isEqualToString:NSCocoaErrorDomain] && [self code] == NSUserCancelledError)
    return YES;
  /* Carbon */
  if ([[self domain] isEqualToString:NSOSStatusErrorDomain] && ([self code] == userCanceledErr || [self code] == kPOSIXErrorECANCELED))
    return YES;
  /* Posix */
  if ([[self domain] isEqualToString:NSPOSIXErrorDomain] && [self code] == ECANCELED)
    return YES;
  /* Mach */
  //  if ([[self domain] isEqualToString:NSMachErrorDomain] && [self code] == KERN_ABORTED)
  //    return YES;
  return NO;
}

@end
