//
//  HM_Config.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_Config.h"
#import "HM_NetWork.h"

@implementation HM_Config

+ (instancetype)sharedManager {
    static HM_Config *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [HM_Config new];
    });
    return config;
}

- (NSString *) getSDKVer{
    return @"3.1.2";
}

- (BOOL)isW2ADataString:(NSString *)inputString {
    NSString *pattern = @"w2a_data(:|%3[aA])[a-zA-Z0-9_/]*?_bi";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        NSLog(@"正则表达式错误: %@", error.localizedDescription);
        return NO;
    }
    NSRange range = NSMakeRange(0, inputString.length);
    NSUInteger matchCount = [regex numberOfMatchesInString:inputString options:0 range:range];
    return matchCount > 0;
}

- (NSString *)getGUID {
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

- (NSString *)getTimestamp {
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *timeStampString = [NSString stringWithFormat:@"%.0f", timeStamp];
    return timeStampString;
}

- (NSNumber *)getTimestampNumber {
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    long timestampAsLong = (long)currentTimestamp;
    NSNumber *timestampAsNumber = [NSNumber numberWithLong:timestampAsLong];
    return timestampAsNumber;
}

- (NSString *)optimizedEscapePipeInString:(NSString *)inputString {
    return inputString ? [inputString stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"] : nil;
}

- (BOOL)shouldReportTodayAndUpdate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *currentDateString = [formatter stringFromDate:[NSDate date]];
    NSString *lastSessionDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSessionDate"];
    if ([currentDateString isEqualToString:lastSessionDate]) {
        return NO;
    }
    [[NSUserDefaults standardUserDefaults] setObject:currentDateString forKey:@"lastSessionDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (void)setLogEnabled:(BOOL)isEnable {
    [[HM_NetWork shareInstance] setLogEnabled:isEnable];
}

@end
