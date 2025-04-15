//
//  HM_Event.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_Event.h"
#import "HM_NetWork.h"

#define baseURL @"https://sl.bi4sight.com"
#define slattibute @"slattibute"

#ifdef DEBUG
#define baseWAURL @"https://cdn.bi4sight.com"
//#define baseWAURL @"https://wa-test.bi4sight.com"
#else
#define baseWAURL @"https://cdn.bi4sight.com"
//#define baseWAURL @"https://wa-test.bi4sight.com"
#endif

#define attribute @"w2a/v10/attribute"

#define setdevice @"w2a/v10/setdevice"

#define session @"w2a/v10/session"

#define purchase @"w2a/v10/purchase"

#define eventpost @"w2a/v10/eventpost"

#define setuserdata @"w2a/v10/setuserdata"

#define launch @"w2a/v10/launch"

@implementation HM_Event

+ (instancetype)sharedInstance {
    static HM_Event *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


- (void)event:(NSString *)eventName withValues:(NSDictionary * _Nullable)values andBlock : (void(^)(NSDictionary * responseObject))block {
    if ([self isRequestGetWithEvent:eventName]) {
        [[HM_NetWork shareInstance] requestJsonGet:[self setUrlWithEvent:eventName] params:values successBlock:^(NSDictionary * _Nonnull responseObject) {
            NSString *code = [responseObject[@"code"] stringValue];
            if ([code isEqual: @"0"]) {
                block(responseObject);
            }
        } failBlock:^(NSError * _Nonnull error) {
            
        }];
    } else {
        [[HM_NetWork shareInstance] requestJsonPost:[self setUrlWithEvent:eventName] params:values successBlock:^(NSDictionary * _Nonnull responseObject) {
            NSString *code = [responseObject[@"code"] stringValue];
            if ([code isEqual: @"0"]) {
                block(responseObject);
            }
        } failBlock:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (BOOL) isRequestGetWithEvent : (NSString *)eventName{
    BOOL isGet = false;//Post请求
    if ([eventName isEqualToString: @"CompleteRegistration"]) {
        isGet = false;
    }else if ([eventName isEqualToString:@"UpDateUserInfo"]) {
        isGet = false;
    } else if ([eventName isEqualToString:@"UploadDeviceInfo"]) {
        isGet = false;
    } else if ([eventName isEqualToString:@"OnSession"]) {
        isGet = true;
    } else if ([eventName isEqualToString:@"Purchase"] || [eventName isEqualToString:@"BI_Purchase"] || [eventName isEqualToString:@"CompletePayment"]) {
        isGet = false;
    } else if ([eventName isEqualToString:@"Launch"]) {
        isGet = false;
    } else {
        isGet = true;
    }
    return isGet;
}

- (NSString *)setUrlWithEvent : (NSString *)eventName {
    NSString *host = baseWAURL;
    NSString *path = @"";
    if ([eventName isEqualToString: @"CompleteRegistration"]) {
        path = attribute;
    }else if ([eventName isEqualToString:@"UpDateUserInfo"]) {
        path = setuserdata;
    } else if ([eventName isEqualToString:@"UploadDeviceInfo"]) {
        path = setdevice;
    } else if ([eventName isEqualToString:@"OnSession"]) {
        path = session;
    } else if ([eventName isEqualToString:@"Purchase"] || [eventName isEqualToString:@"BI_Purchase"] || [eventName isEqualToString:@"CompletePayment"]) {
        path = purchase;
    } else if ([eventName isEqualToString:@"Launch"]) {
        path = launch;
    } else {
        path = eventpost;
    }
    NSString *url = [NSString stringWithFormat:@"%@/%@", host, path];
    return url;
}

@end
