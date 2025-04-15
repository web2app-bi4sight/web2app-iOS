//
//  HM_DeviceData.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface HM_DeviceData : NSObject

+(instancetype) sharedManager;

- (NSDictionary *) getDeviceInofWithDictionary;

- (NSArray *) getDeviceInfoWithArray;

@end

NS_ASSUME_NONNULL_END
