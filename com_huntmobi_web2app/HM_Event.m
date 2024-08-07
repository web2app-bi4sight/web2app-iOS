//
//  HM_Event.m
//  web2app
//
//  Created by HM on 2024/07/11.
//

#import "HM_Event.h"
#import "HM_NetWork.h"

#define baseURL @"https://sl.bi4sight.com"

#define slattibute @"slattibute"

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
    [[HM_NetWork shareInstance] requestJsonPost:[self setUrlWithEvent:eventName] params:values successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            block(responseObject);
        }
    } failBlock:^(NSError * _Nonnull error) {
        
    }];
}

- (NSString *)setUrlWithEvent : (NSString *)eventName {
    NSString *host = baseURL;
    NSString *path = @"";
    if ([eventName isEqualToString: @"CompleteRegistration"]) {
        path = slattibute;
    }
    NSString *url = [NSString stringWithFormat:@"%@/%@", host, path];
    return url;
}

@end
