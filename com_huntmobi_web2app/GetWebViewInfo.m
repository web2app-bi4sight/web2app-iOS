//
//  GetWebViewInfo.m
//  HM
//
//  Created by CCC on 2023/5/17.
//

#import "GetWebViewInfo.h"

@interface GetWebViewInfo () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@end

@implementation GetWebViewInfo

+ (instancetype)shared
{
    static GetWebViewInfo *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[GetWebViewInfo alloc] init];
        manager.isEnable = true;
    });
    return manager;
}

-(void)useFingerPrinting:(BOOL)isEnable {
    self.isEnable = isEnable;
}

-(void)creatWebView {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"" forKey:@"HM_WebView_Fingerprint"];
    [userDefaults synchronize];
    if (self.isEnable) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(10000, 10000, 1, 1)];
         _webView.UIDelegate = self;
         _webView.navigationDelegate = self;
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"fingerprint" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:request];
    }
}

-(void)creatWebView : (void(^)(NSString * string))block {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"" forKey:@"HM_WebView_Fingerprint"];
    [userDefaults synchronize];
    if (self.isEnable) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(10000, 10000, 1, 1)];
         _webView.UIDelegate = self;
         _webView.navigationDelegate = self;
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"com_huntmobi_web2app_Bundle" ofType: @"bundle" ];
        NSString *urlPath = [bundlePath stringByAppendingPathComponent:@"fingerprint.html"];
        NSURL *pathURL = [NSURL fileURLWithPath:urlPath];
        NSURLRequest *request = [NSURLRequest requestWithURL:pathURL];
        [_webView loadRequest:request];

        //开始倒计时
            __block NSInteger time = 10; //倒计时时间
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
            dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
            dispatch_source_set_event_handler(_timer, ^{
                if(time <= 0){ //倒计时结束，关闭
                    dispatch_source_cancel(_timer);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block(@"");
                    });
                }else{
                    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
                    NSString *jsonString = [userDefaults objectForKey:@"HM_WebView_Fingerprint"];
                    if (jsonString.length > 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(jsonString);
                        });
                        dispatch_source_cancel(_timer);
                    }
                    time--;
                }
            });
            dispatch_resume(_timer);

    } else {
        block(@"");
    }
}

- (UIWindow *)getKeyWindow {
    if (@available(iOS 13.0,*)) {
        NSArray *arr = [[[UIApplication sharedApplication] connectedScenes] allObjects];
        UIWindowScene *windowScene =  (UIWindowScene *)arr[0];
        UIWindow *mainWindow = [windowScene valueForKeyPath:@"delegate.window"];
        if(mainWindow){
            return mainWindow;
        }else{
            return [UIApplication sharedApplication].windows.lastObject;
        }
    }else {
        return [UIApplication sharedApplication].keyWindow;
    }
}

-(void) removeWeb {
    if (_webView) {
        _webView.UIDelegate = nil;
        _webView.navigationDelegate = nil;
        [_webView removeFromSuperview];
        _webView = nil;
    }
}

//MARK: web代理
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript: @"jsCallOCReturnMethod()"
                  completionHandler:^(id response, NSError * error) {
        }];
    });
}


- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    if (prompt) {
        // defaultText  是JS 传的JsonString参数
        if ([prompt isEqualToString:@"jsCallOCReturnJsonStringMethod"]) {
//            NSLog(@"%@", defaultText);
            [self setWebInfo:defaultText];
            completionHandler(@"");
        }
    }
}

-(void) setWebInfo:(NSString *) string {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:string forKey:@"HM_WebView_Fingerprint"];
    [userDefaults synchronize];
}


- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
}

@end
