/*
 *  WBThreadPort.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBThreadPort.h)

#include <pthread.h>
#include <libkern/OSAtomic.h>

@interface _WBThreadProxy : NSProxy {
@private
  id wb_target;
  SInt8 wb_sync;
  WBThreadPort *wb_port;
  mach_msg_timeout_t wb_timeout;
}

+ (id)proxyWithPort:(WBThreadPort *)port target:(id)target sync:(NSUInteger)sync timeout:(uint32_t)timeout;
- (id)initWithPort:(WBThreadPort *)port target:(id)target sync:(NSUInteger)sync timeout:(uint32_t)timeout;

@end

@interface WBThreadPort ()

- (void)invalidate;

@end

#pragma mark Mach types
typedef struct {
  mach_msg_header_t header;
  intptr_t invocation;
  bool async;
} wbinvoke_msg;

typedef struct {
  mach_msg_header_t header;
  intptr_t exception;
  mach_msg_trailer_t trailer;
} wbreply_msg;

/* atomic counter */
static int32_t msg_uid = 0;
static WBThreadPort *sMainThread = nil;

static
void _WBTPMachMessageCallBack(CFMachPortRef port, void *msg, CFIndex size, void *info) {
  [(id)info handleMachMessage:msg];
}

#pragma mark Thread Specific
/* Each thread can have a send port (mach_port_t) and a receive port (WBThreadPort *) */
static pthread_key_t sThreadSendPortKey;
static pthread_key_t sThreadReceivePortKey;

static
mach_port_t _WBThreadGetSendPort(void) {
  /* Return the current thread send port */
  mach_port_t port = (mach_port_t)(intptr_t)pthread_getspecific(sThreadSendPortKey);
  if (!port) {
    kern_return_t err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    if (KERN_SUCCESS != err) {
      port = MACH_PORT_NULL;
      DCLog("mach_port_allocate : %s", mach_error_string(err));
    } else if (0 != pthread_setspecific(sThreadSendPortKey, (void *)(intptr_t)port)) {
      DCLog("pthread_setspecific error");
      mach_port_destroy(mach_task_self(), port);
      port = MACH_PORT_NULL;
    }
  }
  return port;
}

static
void _WBThreadSendPortDestructor(void *ptr) {
  mach_port_t sport = (mach_port_t)(intptr_t)ptr;
  if (MACH_PORT_VALID(sport)) {
    /* delete receive rights */
    kern_return_t err = mach_port_destroy(mach_task_self(), sport);
    if (KERN_SUCCESS != err)
      WBCLogWarning("mach_port_destroy: %s", mach_error_string(err));
  }
}

static
void _WBThreadReceivePortDestructor(void *ptr) {
  WBThreadPort *port = (WBThreadPort *)ptr;
  if (port) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    /* invalidate main thread */
    if (port == sMainThread)
      sMainThread = nil;
    
    [port invalidate];
    [port release];
    
    [pool release];
  }
}

@implementation WBThreadPort

+ (void)load {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willBecomeMultiThreaded:)
                                               name:NSWillBecomeMultiThreadedNotification
                                             object:nil];
}

+ (void)willBecomeMultiThreaded:(NSNotification *)aNotification {
  if (!sMainThread)
    sMainThread = [self currentPort];
}

+ (void)initialize {
  if ([WBThreadPort class] == self) {
    verify(0 == pthread_key_create(&sThreadSendPortKey, _WBThreadSendPortDestructor));
    verify(0 == pthread_key_create(&sThreadReceivePortKey, _WBThreadReceivePortDestructor));
  }
}

+ (WBThreadPort *)mainThreadPort {
  if (!sMainThread && pthread_main_np())
    sMainThread = [self currentPort];
  return sMainThread;
}

- (id)wb_init {
  /* return current port if exists */
  WBThreadPort *current = (WBThreadPort *)pthread_getspecific(sThreadReceivePortKey);
  if (current) {
    [self release];
    return current;
  }
  
  if (self = [super init]) {    
    CFMachPortContext ctxt = { 0, self, NULL, NULL, NULL };
    wb_port = CFMachPortCreate(kCFAllocatorDefault, _WBTPMachMessageCallBack, &ctxt, NULL);
    if (!wb_port) {
      DLog(@"Error while creating runloop port");
      [self release];
      return nil;
    }
    
    CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, wb_port, 0);
    if (src) {
      CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], src, kCFRunLoopCommonModes);
      CFRelease(src);
    }
    
    wb_lock = [[NSLock alloc] init];
    wb_timeout = MACH_MSG_TIMEOUT_NONE;
    wb_thread = [[NSThread currentThread] retain];
  }
  return self;
}

+ (WBThreadPort *)currentPort {
  WBThreadPort *current = (WBThreadPort *)pthread_getspecific(sThreadReceivePortKey);
  if (!current) {
    current = [[WBThreadPort alloc] wb_init];
    
    if (0 != pthread_setspecific(sThreadReceivePortKey, current)) {
      WBCLogWarning("pthread_setspecific failed");
      [current invalidate];
      [current release];
      current = nil;
    }
  }
  return current; // release in pthread_specific destructor => _WBThreadReceivePortDestructor()
}

- (id)init {
  WBLogWarning(@"Invalid initializer. Should use +currentPort instead");
  [self release];
  return [WBThreadPort currentPort];
}

- (void)dealloc {
  [self invalidate];
  [super dealloc];
}

- (void)invalidate {
  @synchronized(self) {
    if (wb_port) {     
      CFMachPortInvalidate(wb_port);
      CFRelease(wb_port);
      wb_port = nil;
      
      [wb_thread autorelease];
      wb_thread = nil;
      
      [wb_lock autorelease];
      wb_lock = nil;
    }
  }
}

#pragma mark -
- (uint32_t)timeout {
  return wb_timeout;
}
- (void)setTimeout:(uint32_t)timeout {
  wb_timeout = timeout;
}
- (NSThread *)targetThread {
  return wb_thread;
}

#pragma mark Base method
- (void)performInvocation:(NSInvocation *)anInvocation waitUntilDone:(NSInteger)shouldWait timeout:(uint32_t)timeout {
  if (![anInvocation target])
		WBThrowException(NSInvalidArgumentException, @"The invocation MUST contains a valid target");
  
  if ([[self targetThread] isEqual:[NSThread currentThread]]) {
    WBLogWarning(@"caller thread is the target thread. You should not use 'thread port' to send intra-thread messages.");
    [anInvocation invoke];
    return;
  }
  
  bool synch;
  if (shouldWait < 0)
    synch = [[anInvocation methodSignature] methodReturnLength] > 0;
  else
    synch = shouldWait != 0;
  
  /* for asynchronous call, we should retains arguments */
  if (!synch && anInvocation)
    [anInvocation retainArguments];
  
  wbinvoke_msg msg;
  bzero(&msg, sizeof(msg));
  mach_msg_header_t *send_hdr = &msg.header;
  send_hdr->msgh_bits = MACH_MSGH_BITS_REMOTE(MACH_MSG_TYPE_COPY_SEND);
  send_hdr->msgh_size = (mach_msg_size_t)sizeof(msg);
  send_hdr->msgh_local_port = MACH_PORT_NULL;
  send_hdr->msgh_remote_port = CFMachPortGetPort(wb_port);
  send_hdr->msgh_id = OSAtomicIncrement32(&msg_uid);
  
  if (synch) {
    send_hdr->msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND_ONCE);
    send_hdr->msgh_local_port = _WBThreadGetSendPort();
  }
  msg.async = !synch;
  msg.invocation = (intptr_t)[anInvocation retain];
  
  /* Send invocation to target thread */
  mach_msg_option_t opts = MACH_SEND_MSG;
  if (timeout != MACH_MSG_TIMEOUT_NONE) opts |= MACH_SEND_TIMEOUT;
  mach_error_t err = mach_msg(send_hdr, opts, send_hdr->msgh_size, 0, MACH_PORT_NULL, timeout, MACH_PORT_NULL);
  /* handle result */
  if (MACH_MSG_SUCCESS != err) {
    /* invocation is released by the target thread, 
     so if an error occured, it is not released */
    [anInvocation release];
    switch (err) {
      case MACH_SEND_TIMED_OUT:
				WBThrowException(NSPortTimeoutException, @"timeout occured while sending invocation");
        break;
      default:
				WBThrowException(NSPortSendException, @"mach_msg(send) return (%#x): %s", err, mach_error_string(err));
        break;
    }
  } else if (synch) {
    /* if should wait response */
    wbreply_msg reply;
    bzero(&reply, sizeof(reply));
    mach_msg_header_t *recv_hdr = &reply.header;
    
    /* loop until you received the expected message */
    do {
      /* reconfigure message before each msg_send call */
      opts = MACH_RCV_MSG;
      recv_hdr->msgh_size = (mach_msg_size_t)sizeof(reply);
      recv_hdr->msgh_local_port = send_hdr->msgh_local_port;
      if (timeout != MACH_MSG_TIMEOUT_NONE) opts |= MACH_RCV_TIMEOUT;
      /* wait reply */
      err = mach_msg(recv_hdr, opts, 0, recv_hdr->msgh_size, recv_hdr->msgh_local_port, timeout, MACH_PORT_NULL);
      /* should never append */
      if (err == MACH_MSG_SUCCESS && recv_hdr->msgh_id != send_hdr->msgh_id) {
        WBCLogWarning("Unexpected message: id is %i and should be %i", recv_hdr->msgh_id, send_hdr->msgh_id);
      }
    } while (err == MACH_MSG_SUCCESS && recv_hdr->msgh_id != send_hdr->msgh_id);
    
    /* handle result */
    switch (err) {
      case MACH_MSG_SUCCESS:
        if (reply.exception) {
          @throw [(id)reply.exception autorelease];
        }
        break;
      case MACH_RCV_TIMED_OUT:
				WBThrowException(NSPortTimeoutException, @"timeout occured while waiting response");
        break;
      default:
        WBThrowException(NSPortReceiveException, @"mach_msg(recv) return (%#x): %s", err, mach_error_string(err));
        break;
    }
  }
}

#pragma mark Automatic forwarding
- (id)wb_prepareWithInvocationTarget:(id)target waitUntilDone:(NSInteger)synch {
  if (!wb_thread)
		WBThrowException(NSInvalidArgumentException, @"call method on invalid port");
  
  [wb_lock lock];
  wb_sync = synch;
  wb_target = target;
  return self;
}

- (id)prepareWithInvocationTarget:(id)target {
  return [self wb_prepareWithInvocationTarget:target waitUntilDone:kWBThreadPortWaitIfReturns];
}

- (id)prepareWithInvocationTarget:(id)target waitUntilDone:(NSInteger)synch {
  return [self wb_prepareWithInvocationTarget:target waitUntilDone:synch];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  if (!wb_target)
    [super methodSignatureForSelector:aSelector];
  
  return [wb_target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  id target = wb_target;
  wb_target = nil;
  [wb_lock unlock];
  
  if (target && ![target respondsToSelector:[anInvocation selector]]) {
    [target doesNotRecognizeSelector:[anInvocation selector]];
  }
  
  if (!target) {
    [super forwardInvocation:anInvocation];
  } else {
    [anInvocation setTarget:target];
    [self performInvocation:anInvocation waitUntilDone:kWBThreadPortWaitIfReturns timeout:wb_timeout];
  }
}

#pragma mark Message handler
- (void)handleMachMessage:(void *)machMessage {
  wbinvoke_msg *msg = (wbinvoke_msg *)machMessage;
  
  id error = nil;
  NSInvocation *invocation = (NSInvocation *)msg->invocation;
  @try {
    [invocation invoke];
  } @catch (id exception) {
    error = exception;
  }
  if (!msg->async) {
    wbreply_msg reply_msg;
    bzero(&reply_msg, sizeof(reply_msg));
    
    mach_msg_header_t *reply_hdr = &reply_msg.header;
    
    reply_hdr->msgh_id = msg->header.msgh_id;
    reply_hdr->msgh_bits = MACH_MSGH_BITS_REMOTE(msg->header.msgh_bits);
    reply_hdr->msgh_size = (mach_msg_size_t)(sizeof(reply_msg) - sizeof(reply_msg.trailer));
    reply_hdr->msgh_local_port = MACH_PORT_NULL;
    reply_hdr->msgh_remote_port = msg->header.msgh_remote_port;
    
    reply_msg.exception = (intptr_t)[error retain];
    
    mach_msg_option_t opts = MACH_SEND_MSG;
    if (wb_timeout != MACH_MSG_TIMEOUT_NONE) opts |= MACH_SEND_TIMEOUT;
    /* send message */
    mach_error_t err = mach_msg(reply_hdr, opts, reply_hdr->msgh_size, 0, MACH_PORT_NULL, wb_timeout, MACH_PORT_NULL);
    if (MACH_MSG_SUCCESS != err) {
      [error release];
      WBCLogWarning("mach_msg(reply) : %s", mach_error_string(err));
    }
  } else if (error) {
    WBLogWarning(@"exception occured during asynchronous call to [%@ %@]: %@: %@", 
                 [[invocation target] class], NSStringFromSelector([invocation selector]),
                 [error respondsToSelector:@selector(name)] ? [error name] : error,
                 [error respondsToSelector:@selector(reason)] ? [error reason] : @"undefined reason");
  }
  [invocation release];
}

#pragma mark -
#pragma mark Proxy
+ (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)synch {
  return [[self currentPort] proxyWithTarget:target sync:synch];
}
+ (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)synch timeout:(uint32_t)timeout {
  return [[self currentPort] proxyWithTarget:target sync:synch timeout:timeout];
}

- (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)synch {
  return [self proxyWithTarget:target sync:synch timeout:wb_timeout];
}
- (NSProxy *)proxyWithTarget:(id)target sync:(NSUInteger)synch timeout:(uint32_t)timeout {
  return [_WBThreadProxy proxyWithPort:self target:target sync:synch timeout:timeout];
}

@end

@implementation _WBThreadProxy

+ (id)proxyWithPort:(WBThreadPort *)port target:(id)target sync:(NSUInteger)synch timeout:(uint32_t)timeout  {
  return [[[self alloc] initWithPort:port target:target sync:synch timeout:timeout] autorelease];
}

- (id)initWithPort:(WBThreadPort *)port target:(id)target sync:(NSUInteger)synch timeout:(uint32_t)timeout  {
  /* NSProxy does not implements init */
  wb_sync = synch;
  wb_timeout = timeout;
  wb_port = [port retain];
  wb_target = [target retain];
  return self;
}

- (void)dealloc {
  [wb_port release];
  [wb_target release];
  [super dealloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  NSMethodSignature *sign = [wb_target methodSignatureForSelector:aSelector];
  return sign ? : [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  [anInvocation setTarget:wb_target];
  [wb_port performInvocation:anInvocation waitUntilDone:wb_sync timeout:[wb_port timeout]];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  if ([wb_target respondsToSelector:aSelector])
    return YES;
  return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
  return [wb_target conformsToProtocol:aProtocol];
}

- (BOOL)isKindOfClass:(Class)aClass {
  return [wb_target isKindOfClass:aClass];
}

@end
