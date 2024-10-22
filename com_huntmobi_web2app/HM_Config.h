//
//  HM_Config.h
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define HMLog(format, ...) \
do { \
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; \
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"]; \
    NSDate *currentTime = [NSDate date]; \
    NSString *formattedTime = [dateFormatter stringFromDate:currentTime]; \
    NSString *message = [NSString stringWithFormat:(format), ##__VA_ARGS__]; \
    NSLog(@"\n[%@] %@\n", formattedTime, message); \
} while(0)
#else
#define HMLog(format, ...)
#endif

#ifdef DEBUG
#define HMAllLog(message, ...) \
do { \
    NSString *fileName = [[NSString stringWithUTF8String:__FILE__] lastPathComponent]; \
    NSLog(@"\n********** HMAllLog-satrt ***********\n\n文件名称:%@\n方法名称:%s\n行数:%d\n信息:\n\n%@\n\n********** HMAllLog-end ***********\n", fileName, __FUNCTION__, __LINE__, message); \
} while(0)
#else
#define HMAllLog(message, ...)
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HM_Config : NSObject

+(instancetype) sharedManager;

-(void) saveDeviceID;

-(void) saveBaseInfo;

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

- (CGFloat) returnSDKVersion;

- (NSString *)currentUTCTimestamp;

-(NSString *)getGUID;

- (BOOL) isNewUser;

- (NSDictionary *)getWebFingerprint;

- (NSArray<NSString *> *)matchesInString:(NSString *)input;

- (BOOL)isW2ADataString:(NSString *)inputString;

- (BOOL)isW2AKeyString:(NSString *)inputString;
    
@end

NS_ASSUME_NONNULL_END
