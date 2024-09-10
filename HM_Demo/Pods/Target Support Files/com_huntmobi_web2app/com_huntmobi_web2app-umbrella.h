#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "hm.h"
#import "HM_Config.h"
#import "HM_DeviceData.h"
#import "HM_Event.h"
#import "HM_NetWork.h"
#import "HM_SmartLink.h"
#import "HM_WebView.h"

FOUNDATION_EXPORT double com_huntmobi_web2appVersionNumber;
FOUNDATION_EXPORT const unsigned char com_huntmobi_web2appVersionString[];

