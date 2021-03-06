/*
 *  WBThreadPort.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

enum {
  kWBThreadPortWait = 1,
  kWBThreadPortDontWait = 0,
  /* wait if the method returns a value. */
  kWBThreadPortWaitIfReturns = -1,
};

WB_OBJC_EXPORT
WB_DEPRECATED("Use GCD")
@interface WBThreadPort : NSObject {
  @private
  NSThread *wb_thread;
  CFMachPortRef wb_port;

  mach_msg_timeout_t wb_timeout;
}

+ (WBThreadPort *)currentPort;
+ (WBThreadPort *)mainThreadPort;

/* Should use current port instead */
// - (id)init;

- (NSThread *)targetThread;

// WARNING: messages handled by the receiver would not be forwarded (retain, release, etc…)
- (id)prepareWithInvocationTarget:(id)target;
- (id)prepareWithInvocationTarget:(id)target waitUntilDone:(NSInteger)sync;

- (void)performInvocation:(NSInvocation *)anInvocation waitUntilDone:(NSInteger)sync timeout:(uint32_t)timeout;

- (void)performSelector:(SEL)anAction target:(id)aTarget argument:(id)anObject waitUntilDone:(BOOL)waitDone;
- (void)performSelector:(SEL)anAction target:(id)aTarget argument:(id)anObject waitUntilDone:(NSInteger)sync timeout:(uint32_t)timeout;

- (uint32_t)timeout;
- (void)setTimeout:(uint32_t)timeout;

/*!
@method
 @abstract Create a proxy object for the calling thread
 */
+ (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)sync;
+ (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)sync timeout:(uint32_t)timeout;
/*!
  @method
 @abstract Create a proxy object for the receiver target thread.
 */
- (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)sync;
- (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)sync timeout:(uint32_t)timeout;

@end

@interface WBThreadPort (WBThreadDetach)
+ (WBThreadPort *)detachThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)argument;
@end

