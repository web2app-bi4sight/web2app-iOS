//
//  HM_NetWork.m
//  HM
//
//  Created by CCC on 2022/11/22.
//

#import "HM_NetWork.h"
#import "HM_Config.h"

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

@implementation HM_NetWork

+ (instancetype)shareInstance
{
    static HM_NetWork *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[HM_NetWork alloc] init];
        [_sharedInstance configure];
    });
    return _sharedInstance;
}

- (void)configure
{
    self.isEnableLog = false;
    self.requestURL = @"";
}

-(void) setLogEnabled:(BOOL) isEnable {
    self.isEnableLog = isEnable;
}

- (void)requestJsonPost:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock
{

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *HM_DeviceID_Data = [userDefaults stringForKey:@"__hm_uuid__"];
    if (!HM_DeviceID_Data) {
        HM_DeviceID_Data = @"";
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithDictionary:params] options:0 error:nil];
    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@?v=%.1lf", self.requestURL, relativePath, [[HM_Config sharedManager] returnSDKVersion]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:HM_DeviceID_Data forHTTPHeaderField:@"__hm_uuid__"];
//    [request setValue:@"eg-appinfo" forHTTPHeaderField:[[NSBundle mainBundle] bundleIdentifier]];
    request.timeoutInterval = 30;
    
    NSDictionary *requestHeaders = request.allHTTPHeaderFields;
    NSMutableString *headerString = [NSMutableString stringWithString:@"Request Headers:\n"];
    [requestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [headerString appendFormat:@"%@: %@\n", key, obj];
    }];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            if (successBlock) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if (self.isEnableLog) {
                    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (jsonData.length > 0) {
                        HMLog(@"\n**************\n hm_event log \n\nurl:%@\n\n%@\nRequestBody:\n%@\n\nResponse:\n%@\n**************\n\n ", relativePath, headerString, strJson, jsonStr);
                    }
                }
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    successBlock([self changeType:responseObject]);
                }
            }
        } else {
            if (failBlock) {
                if (error) {
                    HMLog(@"**************\n hm_event log\n\nurl:%@\n\nrequestHeaders:\n%@\n\nrequestBody:\n%@\n\nerror:\n%@\n \n**************\n", relativePath, headerString, strJson, error);
                    failBlock(error);
                }
            }
        }
    }];
    [dataTask resume];
}




//将NSDictionary中的Null类型的项目转化成@""
-(NSDictionary *)nullDic:(NSDictionary *)myDic
{
    NSArray *keyArr = [myDic allKeys];
    NSMutableDictionary *resDic = [[NSMutableDictionary alloc]init];
    for (int i = 0; i < keyArr.count; i ++)
    {
        id obj = [myDic objectForKey:keyArr[i]];
        
        obj = [self changeType:obj];
        
        [resDic setObject:obj forKey:keyArr[i]];
    }
    return resDic;
}

//将NSDictionary中的Null类型的项目转化成@""
-(NSArray *)nullArr:(NSArray *)myArr
{
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < myArr.count; i ++)
    {
        id obj = myArr[i];
        
        obj = [self changeType:obj];
        
        [resArr addObject:obj];
    }
    return resArr;
}

//将NSString类型的原路返回
-(NSString *)stringToString:(NSString *)string
{
    return string;
}

//将Null类型的项目转化成@""
-(NSString *)nullToString
{
    return @"";
}

//类型识别:将所有的NSNull类型转化成@""
-(id)changeType:(id)myObj
{
    if ([myObj isKindOfClass:[NSDictionary class]])
    {
        return [self nullDic:myObj];
    }
    else if([myObj isKindOfClass:[NSArray class]])
    {
        return [self nullArr:myObj];
    }
    else if([myObj isKindOfClass:[NSString class]])
    {
        if ([myObj isKindOfClass:[NSString class]]) {
            if (([myObj compare:@"null" options:NSCaseInsensitiveSearch | NSNumericSearch] == NSOrderedSame) || ([myObj compare:@"nil" options:NSCaseInsensitiveSearch | NSNumericSearch] == NSOrderedSame)) {
                return [self nullToString];
            }
        }
        return [self stringToString:myObj];
    }
    else if([myObj isKindOfClass:[NSNull class]])
    {
        return [self nullToString];
    }
    else
    {
        return myObj;
    }
}

@end
