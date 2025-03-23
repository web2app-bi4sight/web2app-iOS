//
//  HM_NetWork.m
//  HM
//
//  Created by CCC on 2022/11/22.
//

#import "HM_NetWork.h"
#import "HM_Config.h"
#import <pthread.h>

@interface HM_NetWork ()
@property (nonatomic, strong) NSOperationQueue *requestQueue;  // 请求队列
@property (nonatomic, strong) NSMutableArray *savedRequests;  // 本地保存的请求队列
@property (nonatomic) pthread_mutex_t requestMutex;  // 线程锁
@property (nonatomic, assign) BOOL hasLoadedRequests; // 标志位

@end

@implementation HM_NetWork

+ (instancetype)shareInstance {
    static HM_NetWork *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[HM_NetWork alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_requestMutex, NULL);  // 初始化线程锁
        [self configure];
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&_requestMutex);  // 销毁线程锁
}

- (void)configure {
    self.isEnableLog = NO;
    self.requestURL = @"";
    self.requestQueue = [[NSOperationQueue alloc] init];
    self.requestQueue.maxConcurrentOperationCount = 1;  // 保持顺序执行
    
    [self loadSavedRequests];  // 加载本地保存的请求
}

#pragma mark - 请求队列本地保存

// 线程安全地将请求保存到本地
- (void)saveRequestToLocalWithMethod:(NSString *)method relativePath:(NSString *)relativePath params:(NSDictionary *)params {
    pthread_mutex_lock(&_requestMutex);  // 加锁
    NSMutableDictionary *requestInfo = [NSMutableDictionary dictionary];
    requestInfo[@"method"] = method;
    requestInfo[@"relativePath"] = relativePath;
    requestInfo[@"params"] = params;
    

    for (int i = 0; i < self.savedRequests.count; i++) {
        NSDictionary *requestInfo = [self.savedRequests objectAtIndex:i];
        NSArray *keys = [requestInfo allKeys];
        if (keys.count > 0) {
            NSString *key = [keys objectAtIndex:0];
            if ([key isEqualToString:[params objectForKey:@"eid"]]) {
                pthread_mutex_unlock(&_requestMutex);  // 解锁
                return; // 如果请求已经存在，则直接返回
            }
        }
    }
    
    [self.savedRequests addObject:@{[params objectForKey:@"eid"] : requestInfo}];
    [self persistRequests];  // 将队列保存到本地
    pthread_mutex_unlock(&_requestMutex);  // 解锁
}

// 使用文件存储代替 NSUserDefaults
- (void)persistRequests {
    NSString *filePath = [self requestQueueFilePath];
    [NSKeyedArchiver archiveRootObject:self.savedRequests toFile:filePath];
}

- (void)loadSavedRequests {
    if (self.hasLoadedRequests) {
        return; // 已加载过请求，避免再次加载
    }
    NSString *filePath = [self requestQueueFilePath];
    self.savedRequests = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath] ?: [NSMutableArray array];
    self.hasLoadedRequests = YES; // 标记为已加载

    // 复制数组来避免遍历时的修改问题
    NSArray *savedRequestsCopy = [self.savedRequests copy];
    
    // 重新添加所有未完成的请求到队列
    for (NSDictionary *requestInfo in savedRequestsCopy) {
        NSArray *values = [requestInfo allValues];
        if (values.count > 0) {
            NSDictionary *info = [values objectAtIndex:0];
            [self addRequestToQueueWithMethod:info[@"method"]
                                 relativePath:info[@"relativePath"]
                                       params:info[@"params"]
                                 successBlock:nil
                                    failBlock:nil];
        }
    }
}

// 获取队列文件路径
- (NSString *)requestQueueFilePath {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documentsDirectory stringByAppendingPathComponent:@"HM_SavedRequests.archive"];
}

// 删除本地保存的请求
- (void)removeRequestFromLocalAtIndex:(NSString *)eid {
    pthread_mutex_lock(&_requestMutex);  // 加锁

    for (int i = 0; i < self.savedRequests.count; i++) {
        NSDictionary *requestInfo = [self.savedRequests objectAtIndex:i];
        NSArray *keys = [requestInfo allKeys];
        if (keys.count > 0) {
            NSString *key = [keys objectAtIndex:0];
            if ([key isEqualToString:eid]) {
                [self.savedRequests removeObjectAtIndex:i];
                [self persistRequests];
                break;
            }
        }
    }
    
    pthread_mutex_unlock(&_requestMutex);  // 解锁
}


#pragma mark - 请求方法

- (void)requestJsonPost:(NSString *)relativePath
                 params:(NSDictionary *)params
           successBlock:(HSResponseSuccessBlock)successBlock
              failBlock:(HSResponseFailBlock)failBlock
{
    [self addRequestToQueueWithMethod:@"POST"
                         relativePath:relativePath
                               params:params
                         successBlock:successBlock
                            failBlock:failBlock];
}

- (void)requestJsonGet:(NSString *)relativePath
                params:(NSDictionary *)params
          successBlock:(HSResponseSuccessBlock)successBlock
             failBlock:(HSResponseFailBlock)failBlock
{
    [self addRequestToQueueWithMethod:@"GET"
                         relativePath:relativePath
                               params:params
                         successBlock:successBlock
                            failBlock:failBlock];
}

#pragma mark - 队列请求管理

- (void)addRequestToQueueWithMethod:(NSString *)method
                       relativePath:(NSString *)relativePath
                             params:(NSDictionary *)params
                       successBlock:(HSResponseSuccessBlock)successBlock
                          failBlock:(HSResponseFailBlock)failBlock
{
    BOOL isHas = NO;
    for (int i = 0; i < self.savedRequests.count; i++) {
        NSDictionary *requestInfo = [self.savedRequests objectAtIndex:i];
        NSArray *keys = [requestInfo allKeys];
        if (keys.count > 0) {
            NSString *key = [keys objectAtIndex:0];
            if ([key isEqualToString:[params objectForKey:@"eid"]]) {
                pthread_mutex_unlock(&_requestMutex);  // 解锁
                isHas = YES;
                break;
            }
        }
    }

    if (!isHas) {
        // 保存请求到本地队列
        [self saveRequestToLocalWithMethod:method relativePath:relativePath params:params];
    }

    // 构建请求任务
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        [self executeRequestWithMethod:method
                          relativePath:relativePath
                                params:params
                          successBlock:^(id responseObject) {
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(responseObject);
                });
            }
            [self handleRequestCompletionForIndex:[params objectForKey:@"eid"]];  // 请求完成后移除
        }
                             failBlock:^(NSError *error) {
            if (failBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failBlock(error);
                });
            }
//            [self handleRequestCompletionForIndex:[params objectForKey:@"eid"]];   // 请求失败也移除
        }];
    }];
    
    [self.requestQueue addOperation:operation];  // 添加请求到队列中
}

#pragma mark - 请求执行

- (void)executeRequestWithMethod:(NSString *)method
                    relativePath:(NSString *)relativePath
                          params:(NSDictionary *)params
                    successBlock:(HSResponseSuccessBlock)successBlock
                       failBlock:(HSResponseFailBlock)failBlock
{
//    if (![relativePath isEqualToString:@"https://cdn.bi4sight.com/w2a/attribute"]) {
    BOOL isContains = [relativePath containsString:@"w2a/attribute"];
    BOOL isW2A = false;
    if ([relativePath containsString:@"https://cdn.bi4sight.com"]) {
        isW2A = true;
    } else if ([relativePath containsString:@"https://capi.bi4sight.com"]) {
        isW2A = true;
    } else if ([relativePath containsString:@"https://wa.bi4sight.com"]) {
        isW2A = true;
    }
    if (!isContains && isW2A) {
        NSString *w2akey = [params objectForKey:@"w2akey"] ?: @"";
        NSString *w2a_data_encrypt = [params objectForKey:@"w2a_data_encrypt"] ?: @"";
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"] ?: @"";
        if (w2a_data_encrypt.length < 1 && w2akey.length < 1) {
//            NSLog(@"没有w2akey");
            if (HM_W2a_Data.length > 0) {
                NSString *click_time = [userDefaults objectForKey:@"HM_CLICK_TIME"];
                if (![self isTimestampOlderThan48Hours:click_time]) {
//                    NSLog(@"重新赋值w2akey");
                    NSString *appname = [userDefaults objectForKey:@"HM_AppName"] ?: @"";

                    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:params];
                    [mDic setObject:HM_W2a_Data forKey:@"w2akey"];
                    [mDic setObject:appname forKey:@"app_name"];
                    params = [NSDictionary dictionaryWithDictionary:mDic];
                } else {
                    [self handleRequestCompletionForIndex:[params objectForKey:@"eid"]];  // 超出48小时移除掉
                }
            } else {
//                NSLog(@"还是没有w2akey");
                return;
            }
        }
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceID = [userDefaults stringForKey:@"__hm_uuid__"] ?: @"";
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@?v=%.1lf",
                           self.requestURL,
                           relativePath,
                           [[HM_Config sharedManager] returnSDKVersion]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = method;
    
    if ([method isEqualToString:@"POST"]) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    [request setValue:deviceID forHTTPHeaderField:@"__hm_uuid__"];
    request.timeoutInterval = 30;
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (failBlock) failBlock(error);
        } else {
            @try {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

                if (self.isEnableLog) {
                    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
                    NSString *requestBodyStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    
                    if (jsonData.length > 0) {
                        NSDictionary *requestHeaders = request.allHTTPHeaderFields;
                        NSMutableString *headerString = [NSMutableString stringWithString:@"Request Headers:\n"];
                        [requestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
                            [headerString appendFormat:@"%@: %@\n", key, obj];
                        }];
                        
                        HMLog(@"\n**************\n hm_event log \n\nurl:%@\n\n%@\nRequestBody:\n%@\n\nResponse:\n%@\n**************\n\n",
                              relativePath, headerString, requestBodyStr, jsonStr);
                    }
                }
                if (successBlock) successBlock([self handleResultData:responseObject]);
            }
            @catch (NSException *exception) {
                NSLog(@"Error occurred: %@, %@", exception, [exception userInfo]);
                if (successBlock) successBlock([self handleResultData:@{}]);
            }
            @finally {
            }
            
        }
    }];
    
    [dataTask resume];
}

#pragma mark - 请求完成处理

- (void)handleRequestCompletionForIndex:(NSString *)eid {
    [self removeRequestFromLocalAtIndex:eid];
    // 检查是否还有未完成的请求，如果有，则自动执行下一条请求
     if (self.savedRequests.count > 0) {
         NSDictionary *nextRequestInfo = [self.savedRequests firstObject];
         NSArray *values = [nextRequestInfo allValues];
         if (values.count > 0) {
             NSDictionary *info = [values objectAtIndex:0];
             [self addRequestToQueueWithMethod:info[@"method"]
                                  relativePath:info[@"relativePath"]
                                        params:info[@"params"]
                                  successBlock:nil
                                     failBlock:nil];
         }
     } else {
         
     }
}

#pragma mark - 结果处理

- (NSDictionary *)handleResultData:(NSDictionary *)data {
    return [self changeType:data];
}

- (void)setLogEnabled:(BOOL)isEnable {
    self.isEnableLog = isEnable;
}

#pragma mark - 类型转换

- (id)changeType:(id)myObj {
    if ([myObj isKindOfClass:[NSDictionary class]]) {
        return [self nullDic:myObj];
    } else if ([myObj isKindOfClass:[NSArray class]]) {
        return [self nullArr:myObj];
    } else if ([myObj isKindOfClass:[NSString class]]) {
        if ([myObj isEqual:@"null"] || [myObj isEqual:@"nil"]) {
            return @"";
        }
        return myObj;
    } else if ([myObj isKindOfClass:[NSNull class]]) {
        return @"";
    } else {
        return myObj;
    }
}

- (NSDictionary *)nullDic:(NSDictionary *)myDic {
    NSMutableDictionary *resDic = [NSMutableDictionary dictionary];
    for (NSString *key in myDic) {
        id obj = [myDic objectForKey:key];
        obj = [self changeType:obj];
        [resDic setObject:obj forKey:key];
    }
    return resDic;
}

- (NSArray *)nullArr:(NSArray *)myArr {
    NSMutableArray *resArr = [NSMutableArray array];
    for (id obj in myArr) {
        [resArr addObject:[self changeType:obj]];
    }
    return resArr;
}

- (BOOL)isTimestampOlderThan48Hours:(NSString *)timestampString {
    NSTimeInterval timestampInterval = [timestampString doubleValue];
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval currentTimeInterval = [currentDate timeIntervalSince1970];
    
    NSTimeInterval timeDifference = currentTimeInterval - timestampInterval;
    
    NSTimeInterval hours48InSeconds = 48 * 60 * 60;
    
    // 判断是否大于 48 小时
    return timeDifference > hours48InSeconds;
}


@end
