//
//  GetWebViewInfo.h
//  HM
//
//  Created by CCC on 2023/5/17.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GetWebViewInfo : NSObject

@property(nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL isEnable;

+ (instancetype)shared;

-(void) creatWebView: (void(^)(NSString * string))block ;

//-(void) removeWeb;

-(void) useFingerPrinting:(BOOL) isEnable;

@end

NS_ASSUME_NONNULL_END
