//
//  HM_WebView.m
//  web2app
//
//  Created by HM on 2024/07/19.
//
#import "HM_WebView.h"
#import "HM_Config.h"
#import <WebKit/WebKit.h>

@interface HM_WebView () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>
@property(nonatomic, strong) WKWebView *webView;
@end

static HMWebUABlock webUABlock;
static HMWebBlock webBlock;

@implementation HM_WebView

+ (instancetype)shared
{
    static HM_WebView *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HM_WebView alloc] init];
        NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"" forKey:@"HM_WebView_UA"];
        [userDefaults synchronize];
    });
    return manager;
}

- (void)HMWebUABlock:(HMWebUABlock)block {
    if (webUABlock == nil) {
        webUABlock = [block copy];
    }
}

- (void)HMWebBlock:(HMWebBlock)block{
    if (webBlock == nil) {
        webBlock = [block copy];
    }
}


-(void)creatWebView{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *userAgent = [userDefaults objectForKey:@"HM_WebView_UA"];
    if (userAgent != nil && userAgent.length > 0) {
        webBlock();
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(10000, 10000, 1, 1)];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        NSString *html = @"<html><body></body></html>";
        [self.webView loadHTMLString:html baseURL:nil];
    });
}

-(void)creatSLWebView {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *userAgent = [userDefaults objectForKey:@"HM_WebView_UA"];
    if (userAgent != nil && userAgent.length > 0) {
        webUABlock(userAgent);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(10000, 10000, 1, 1)];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        NSString *html = @"<html><body></body></html>";
        [self.webView loadHTMLString:html baseURL:nil];
    });
}



//MARK: web代理
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString *userAgent, NSError *error) {
            NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
            if (error == nil) {
                [userDefaults setObject:userAgent forKey:@"HM_WebView_UA"];
            } else {
                [userDefaults setObject:@"" forKey:@"HM_WebView_UA"];
            }
            [userDefaults synchronize];
            webBlock();
        }];
    });
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
}


@end

