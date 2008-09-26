/*
 *  WBLSFunctions.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBLSFunctions.h)

#pragma mark -
#pragma mark Launch Service
OSType WBLSGetSignatureForPath(CFStringRef path) {
  if (path) {
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, FALSE);
    if (url) {
      LSItemInfoRecord info;
      LSCopyItemInfoForURL((CFURLRef)url,
                           kLSRequestTypeCreator,
                           &info);
      CFRelease(url);
      return (info.creator) ? info.creator : 0;
    }
  }
  return kLSUnknownType;
}

CFStringRef WBLSCopyBundleIdentifierForPath(CFStringRef path) {
  if (!path) return NULL;
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, FALSE);
  CFBundleRef bundle = NULL;
  CFStringRef identifier = NULL;
  if (url) {
    bundle = CFBundleCreate(kCFAllocatorDefault, url);
    CFRelease(url);
  }
  if (bundle) {
    identifier = CFBundleGetIdentifier(bundle);
    if (identifier)
      CFRetain(identifier);
    CFRelease(bundle);
  }
  return identifier;
}

CFURLRef WBLSCopyApplicationURLForSignature(OSType sign) {
  if (!sign || kUnknownType == sign) return NULL;
  CFURLRef application = NULL;
  LSFindApplicationForInfo(sign, NULL, NULL, NULL, &application);
  return application;
}

CFURLRef WBLSCopyApplicationURLForBundleIdentifier(CFStringRef identifier) {
  if (!identifier) return NULL;
  CFURLRef application = NULL;
  LSFindApplicationForInfo(kLSUnknownType, identifier, NULL, NULL, &application);
  return application;
}

OSStatus WBLSGetApplicationForSignature(OSType sign, FSRef *app) {
  if (!sign || kUnknownType == sign) return paramErr;
  return LSFindApplicationForInfo(sign, NULL, NULL, app, NULL);
}

OSStatus WBLSGetApplicationForBundleIdentifier(CFStringRef identifier, FSRef *app) {
  if (!identifier) return paramErr;
  return LSFindApplicationForInfo(kLSUnknownCreator, identifier, NULL, app, NULL);
}

#pragma mark -
OSStatus WBLSIsApplication(const FSRef *aRef, Boolean *isApp) {
  check(aRef);
  check(isApp);
  LSItemInfoRecord info;
  OSStatus err = LSCopyItemInfoForRef(aRef, kLSRequestBasicFlagsOnly, &info);
  if (noErr == err) {
    *isApp = (kLSItemInfoIsApplication & info.flags) != 0;
  }
  return err;
}

OSStatus WBLSIsApplicationAtURL(CFURLRef anURL, Boolean *isApp) {
  check(anURL);
  check(isApp);
  LSItemInfoRecord info;
  OSStatus err = LSCopyItemInfoForURL(anURL, kLSRequestBasicFlagsOnly, &info);
  if (noErr == err) {
    *isApp = (kLSItemInfoIsApplication & info.flags) != 0;
  }
  return err;
}

OSStatus WBLSIsApplicationAtPath(CFStringRef aPath, Boolean *isApp) {
  check(aPath);
  OSStatus err = noErr;
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, aPath, kCFURLPOSIXPathStyle, TRUE);
  if (url) {
    err = WBLSIsApplicationAtURL(url, isApp);
    CFRelease(url);
  } else {
    err = paramErr;
  }
  return err;
}

OSStatus WBLSLaunchApplication(FSRef *app, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  LSApplicationParameters params;
  bzero(&params, sizeof(params));
  params.application = app;
  params.flags = flags;
  params.version = 0;
  return LSOpenApplication(&params, psn);
}

OSStatus WBLSLaunchApplicationAtPath(CFStringRef aPath, CFURLPathStyle pathStyle, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  OSStatus err = paramErr;
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, aPath, pathStyle, TRUE);
  if (url) {
    FSRef ref;
    if (CFURLGetFSRef(url, &ref)) {
      err = WBLSLaunchApplication(&ref, flags, psn);
    } else {
      err = coreFoundationUnknownErr;
    }
    CFRelease(url);
  }
  return err;
}
OSStatus WBLSLaunchApplicationWithSignature(OSType sign, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  FSRef app;
  OSStatus err = WBLSGetApplicationForSignature(sign, &app);
  if (noErr == err) {
    err = WBLSLaunchApplication(&app, flags, psn);
  }
  return err;
}
OSStatus WBLSLaunchApplicationWithBundleIdentifier(CFStringRef bundle, LSLaunchFlags flags, ProcessSerialNumber *psn) {
  FSRef app;
  OSStatus err = WBLSGetApplicationForBundleIdentifier(bundle, &app);
  if (noErr == err) {
    err = WBLSLaunchApplication(&app, flags, psn);
  }
  return err;
}

#pragma mark -
#pragma mark Objective-C
NSString *WBLSFindApplicationForSignature(OSType signature) {
  NSString *path = nil;
  CFURLRef url = WBLSCopyApplicationURLForSignature(signature);
  if (url) {
    path = (id)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    CFRelease(url);
  }
  return path ? [path autorelease] : nil;
}

NSString *WBLSFindApplicationForBundleIdentifier(NSString *bundle) {
  NSString *path = nil;
  CFURLRef url = WBLSCopyApplicationURLForBundleIdentifier((CFStringRef)bundle);
  if (url) {
    path = (id)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    CFRelease(url);
  }
  return path ? [path autorelease] : nil;
}

