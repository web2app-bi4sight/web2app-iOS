//
//  HM_Event.h
//  web2app
//
//  Created by HM on 2024/07/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_Event : NSObject

+ (instancetype)sharedInstance;

- (void)event:(NSString *)eventName withValues:(NSDictionary * _Nullable)values andBlock : (void(^)(NSDictionary * responseObject))block ;

- (void)WAEvent:(NSString *)eventName withValues:(NSDictionary * _Nullable)values andBlock : (void(^)(NSDictionary * responseObject))block ;


@end

NS_ASSUME_NONNULL_END
