//
//  HM_Config.h
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_Config : NSObject

+(instancetype) sharedManager;

-(void) saveDeviceID;

-(void) saveBaseInfo;

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

- (CGFloat) returnSDKVersion;

- (NSString *)currentUTCTimestamp;

@end

NS_ASSUME_NONNULL_END
