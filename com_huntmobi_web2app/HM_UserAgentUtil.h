//
//  HM_UserAgentUtil.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_UserAgentUtil : NSObject

+ (void)getUserAgentWithCompletion:(void (^)(NSString *userAgent))completion;

@end

NS_ASSUME_NONNULL_END

