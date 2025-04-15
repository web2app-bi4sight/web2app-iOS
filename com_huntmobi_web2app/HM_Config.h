//
//  HM_Config.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>

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

-(BOOL) isW2ADataString : (NSString *)inputString;

-(NSString *) getGUID;

-(NSString *) getTimestamp;

-(NSNumber *) getTimestampNumber;

-(NSString *)optimizedEscapePipeInString : (NSString *)inputString;

- (BOOL)shouldReportTodayAndUpdate;

-(void) setLogEnabled:(BOOL)isEnable;

-(NSString *)getSDKVer;

@end

NS_ASSUME_NONNULL_END
