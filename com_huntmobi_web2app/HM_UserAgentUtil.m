//
//  HM_UserAgentUtil.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_UserAgentUtil.h"
#import <WebKit/WebKit.h>
#import "HM_Config.h"

@implementation HM_UserAgentUtil

+ (void)getUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
     dispatch_async(dispatch_get_main_queue(), ^{
          HMLog(@"---开始获取UA---");
          __block NSString *cachedUserAgent = @"";
          __block WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
          [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
               if (!error && [result isKindOfClass:[NSString class]]) {
                    cachedUserAgent = [result copy];
                    HMLog(@"%@", cachedUserAgent);
               }
               completion(cachedUserAgent);
               webView = nil;
          }];
     });
}


@end
