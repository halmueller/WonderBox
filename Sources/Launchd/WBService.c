//
//  WBService.m
//  dæmon
//
//  Created by Jean-Daniel Dupas on 18/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#include "WBService.h"

#include <launch.h>
#include <mach/mach_time.h>

static struct _WBServiceContext {
  uint64_t idle;
  mach_port_t ports;
  mach_port_t timer;
  mach_port_t service;
  WBServiceDispatch dispatch;
} sServiceContext;

extern mach_port_name_t mk_timer_create(void);
extern kern_return_t mk_timer_destroy(mach_port_name_t);
extern kern_return_t mk_timer_arm(mach_port_name_t, uint64_t);
extern kern_return_t mk_timer_cancel(mach_port_name_t, uint64_t*);

static
boolean_t _WBServiceDemuxer(mach_msg_header_t *msg, mach_msg_header_t *reply) {
  if (msg->msgh_local_port == sServiceContext.service) {
    if (sServiceContext.timer) // reset timer
      mk_timer_arm(sServiceContext.timer, mach_absolute_time() + sServiceContext.idle);
    
    WBServiceDispatch dispatch = sServiceContext.dispatch;
    // FIXME: barrier
    if (dispatch) return dispatch(msg, reply);
  } else { // assume this is the timer
    WBServiceStop();
  }
  return false;
}

static 
int _WBServiceSendMessage(const char *msg, launch_data_t *outResponse) {
  launch_data_t request = launch_data_new_string(msg);
  if (!request) return errno;
  
  int err = 0;
  launch_data_t response;
  if ((response = launch_msg(request)) == NULL) {
    err = errno;
  } else {
    switch (launch_data_get_type(response)) {
        // launchd will return an errno if an error occurs
      case LAUNCH_DATA_ERRNO:
        err = launch_data_get_errno(response);
        launch_data_free(response);
        break;        
      default:
        if (outResponse) 
          *outResponse = response;
        else
          launch_data_free(response);
        break;
    }
  }
  launch_data_free(request);
  return err;
}

static mach_port_t _WBServiceCheckIn(const char *name, CFErrorRef *outError) {
  launch_data_t service;
  if (_WBServiceSendMessage(LAUNCH_KEY_CHECKIN, &service) != 0)
    return MACH_PORT_NULL;
  
  mach_port_t result = MACH_PORT_NULL;
  launch_data_t ports = launch_data_dict_lookup(service, LAUNCH_JOBKEY_MACHSERVICES);
  if (ports) {
    launch_data_t port = launch_data_dict_lookup(ports, name);
    if (port)
      result = launch_data_get_machport(port);
  }
  launch_data_free(service);
  if (!result && outError)
    *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainMach, KERN_INVALID_NAME, NULL);
  return result;
}

bool WBServiceRun(const char *name, WBServiceDispatch dispatch, mach_msg_size_t msgMaxSize, CFTimeInterval idle, CFErrorRef *outError) {
  assert(!sServiceContext.ports && "Service already running");
  
  // checkin
  sServiceContext.idle = idle;
  sServiceContext.dispatch = dispatch;
  sServiceContext.service = _WBServiceCheckIn(name, outError);
  if (!sServiceContext.service) return false;
  
  kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_PORT_SET, &sServiceContext.ports);
  if (KERN_SUCCESS == kr) 
    kr = mach_port_move_member(mach_task_self(), sServiceContext.service, sServiceContext.ports);
  
  if (KERN_SUCCESS == kr) {
    if (idle > 0) {
      // setup idle timer
      struct mach_timebase_info info;
      mach_timebase_info(&info);    
      sServiceContext.idle = llround((idle * 1.0e9 / (double)info.numer) * (double)info.denom);
      sServiceContext.timer = mk_timer_create();
      if (sServiceContext.timer)
        kr = mk_timer_arm(sServiceContext.timer, mach_absolute_time() + sServiceContext.idle);  
      else
        kr = KERN_INVALID_OBJECT;
      
      if (KERN_SUCCESS == kr)
        kr = mach_port_move_member(mach_task_self(), sServiceContext.timer, sServiceContext.ports);
    }
  }
  
  if (KERN_SUCCESS != kr) {
    if (outError)
      *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainMach, kr, NULL);
    return false;
  }
    
  kr = mach_msg_server(_WBServiceDemuxer, msgMaxSize > 0 ? msgMaxSize : 512, sServiceContext.ports, MACH_RCV_LARGE);
  DCLog("mach_msg_server: %s", mach_error_string(kr));
  return true;
}

void WBServiceStop(void) {
  if (sServiceContext.ports) {
    mach_port_destroy(mach_task_self(), sServiceContext.ports);
    sServiceContext.ports = MACH_PORT_NULL;
  }
  if (sServiceContext.timer) {
    mk_timer_destroy(sServiceContext.timer);
    sServiceContext.timer = MACH_PORT_NULL;
  }
  memset(&sServiceContext, 0, sizeof(sServiceContext));
}
