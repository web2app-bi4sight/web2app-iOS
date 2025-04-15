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
@property (nonatomic, strong) NSOperationQueue *requestQueue;
@property (nonatomic, strong) NSMutableArray *savedRequests;
@property (nonatomic) pthread_mutex_t requestMutex;
@property (nonatomic, assign) BOOL hasLoadedRequests;
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
        pthread_mutex_init(&_requestMutex, NULL);
        [self configure];
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&_requestMutex);
}

- (void)configure {
    self.isEnableLog = NO;
    self.requestURL = @"";
    self.requestQueue = [[NSOperationQueue alloc] init];
    self.requestQueue.maxConcurrentOperationCount = 1;
    [self loadSavedRequests];
}

#pragma mark - 本地持久化处理
- (BOOL)saveRequestToLocalWithMethod:(NSString *)method
                       relativePath:(NSString *)relativePath
                             params:(NSDictionary *)params {
    pthread_mutex_lock(&_requestMutex);
    
    NSString *eid = params[@"eid"];
    if (!eid) {
        pthread_mutex_unlock(&_requestMutex);
        return NO;
    }
    
    // 检查重复eid
    for (NSDictionary *requestInfo in self.savedRequests) {
        if ([requestInfo.allKeys.firstObject isEqualToString:eid]) {
            pthread_mutex_unlock(&_requestMutex);
            return NO;
        }
    }
    
    // 构建存储结构
    NSDictionary *requestData = @{
        @"method": method,
        @"relativePath": relativePath,
        @"params": params
    };
    [self.savedRequests addObject:@{eid: requestData}];
    [self persistRequests];
    
    pthread_mutex_unlock(&_requestMutex);
    return YES;
}

- (void)persistRequests {
    NSString *filePath = [self requestQueueFilePath];
    NSError *error = nil;
    
    // 使用NSKeyedArchiver进行归档
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.savedRequests requiringSecureCoding:NO error:&error];
    
    if (error) {
         HMLog(@"Failed to persist requests: %@", error.localizedDescription);
    } else {
        [data writeToFile:filePath atomically:YES];
    }
}

- (void)loadSavedRequests {
    if (_hasLoadedRequests) return;
    
    NSString *filePath = [self requestQueueFilePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    NSError *error = nil;
    // 使用NSKeyedUnarchiver进行反归档
    NSArray *saved = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:data error:&error];
    
    if (error) {
         HMLog(@"Failed to load saved requests: %@", error.localizedDescription);
    }
    
    self.savedRequests = saved ? [saved mutableCopy] : [NSMutableArray new];
    
    // 添加历史请求到队列
    for (NSDictionary *requestInfo in self.savedRequests) {
        NSString *eid = requestInfo.allKeys.firstObject;
        NSDictionary *data = requestInfo[eid];
        if (data) {
            NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
                [self executeRequestWithMethod:data[@"method"]
                                 relativePath:data[@"relativePath"]
                                       params:data[@"params"]
                                 successBlock:^(id response) {
                    [self handleRequestCompletionForEid:eid];
                } failBlock:^(NSError *error) {
                    // 失败保持请求以便重试
                }];
            }];
            [self.requestQueue addOperation:op];
        }
    }
    _hasLoadedRequests = YES;
}


- (NSString *)requestQueueFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingPathComponent:@"HM_RequestQueue.plist"];
}

#pragma mark - 请求管理
- (void)addRequestToQueueWithMethod:(NSString *)method
                       relativePath:(NSString *)relativePath
                             params:(NSDictionary *)params
                       successBlock:(HSResponseSuccessBlock)successBlock
                          failBlock:(HSResponseFailBlock)failBlock {
    // 尝试保存到本地（包含去重检查）
    if (![self saveRequestToLocalWithMethod:method relativePath:relativePath params:params]) {
        return;
    }
    
    // 创建网络操作
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self executeRequestWithMethod:method
                         relativePath:relativePath
                               params:params
                         successBlock:^(id response) {
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(response);
                });
            }
            [self handleRequestCompletionForEid:params[@"eid"]];
        } failBlock:^(NSError *error) {
            if (failBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failBlock(error);
                });
            }
        }];
    }];
    
    [self.requestQueue addOperation:operation];
}

- (void)handleRequestCompletionForEid:(NSString *)eid {
    pthread_mutex_lock(&_requestMutex);
    // 移除本地存储
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    [self.savedRequests enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(NSDictionary *)obj allKeys].firstObject isEqualToString:eid]) {
            [indexes addIndex:idx];
        }
    }];
    [self.savedRequests removeObjectsAtIndexes:indexes];
    [self persistRequests];
    pthread_mutex_unlock(&_requestMutex);
}

#pragma mark - 网络请求核心
- (void)executeRequestWithMethod:(NSString *)method
                    relativePath:(NSString *)relativePath
                          params:(NSDictionary *)params
                    successBlock:(HSResponseSuccessBlock)successBlock
                       failBlock:(HSResponseFailBlock)failBlock {
    // 参数预处理
    NSMutableDictionary *mParams = [params mutableCopy];
    if ([self shouldHandleW2AKeyForPath:relativePath]) {
        [self processW2AKeyForParams:mParams];
    }
    
    // 构建请求
    NSString *fullURL = [NSString stringWithFormat:@"%@%@",
                         self.requestURL,
                         relativePath];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
    request.HTTPMethod = method;
    
    NSString *paramsString = @"";
    NSMutableArray *mArr = [NSMutableArray arrayWithArray:[params objectForKey:@"dataArray"]];
    if (mArr.count > 0) {
        for (int i = 0; i < mArr.count; i++) {
            NSString *string = [NSString stringWithFormat:@"%@",  mArr[i]];
            mArr[i] = [[HM_Config sharedManager] optimizedEscapePipeInString:string];
        }
        paramsString = [mArr componentsJoinedByString:@"|"];
    }
    if ([method isEqualToString:@"POST"]) {
        // 处理POST请求体
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        // 对参数进行URL编码
        NSString *encodedParamsString = [paramsString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

        // 构建带参数的URL
        NSString *urlString = [NSString stringWithFormat:@"%@%@?p=%@",self.requestURL, relativePath, encodedParamsString];
        NSURL *url = [NSURL URLWithString:urlString];

        // 创建GET请求
        request = [NSMutableURLRequest requestWithURL:url];
    }
    
    // 设置头信息
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *ua = [ud stringForKey:@"HM_WebView_UA"] ?: @"";
    NSString *deviceID = [ud stringForKey:@"__hm_uuid__"] ?: @"";
    NSString *an = [ud stringForKey:@"HM_AppName"] ?: @"";
    NSString *evnetName = [params objectForKey:@"event_name"] ?: @"";

    [request setValue:ua forHTTPHeaderField:@"User-Agent"];
    [request setValue:deviceID forHTTPHeaderField:@"__hm_uuid__"];
    [request setValue:an forHTTPHeaderField:@"__an__"];
    [request setValue:[[HM_Config sharedManager] getSDKVer] forHTTPHeaderField:@"__sv__"];
    if (evnetName.length > 0) {
        [request setValue:evnetName forHTTPHeaderField:@"__en__"];
    }

    // 执行请求
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                 completionHandler:^(NSData *data,
                                                     NSURLResponse *response,
                                                     NSError *error) {
        if (error) {
            if (failBlock) failBlock(error);
            return;
        }
        // 成功处理
        @try {
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:kNilOptions
                                                                          error:nil];
            [self logRequest:request params:paramsString response:data];
            
            if (successBlock) {
                successBlock([self processResponseData:responseDict]);
            }
        } @catch (NSException *exception) {
            if (successBlock) successBlock(@{});
        }
    }];
    [task resume];
}

#pragma mark - 辅助方法
- (BOOL)shouldHandleW2AKeyForPath:(NSString *)path {
    return [path containsString:@"w2a/attribute"] &&
    ([path containsString:@"cdn.bi4sight.com"] ||
     [path containsString:@"capi.bi4sight.com"] ||
     [path containsString:@"wa.bi4sight.com"]);
}

- (void)processW2AKeyForParams:(NSMutableDictionary *)params {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *w2aKey = [ud stringForKey:@"HM_W2a_Data"];
    NSString *clickTime = [ud stringForKey:@"HM_CLICK_TIME"];
    // 检查48小时有效期
    if (w2aKey.length > 0 && ![self isTimestampExpired:clickTime]) {
        params[@"w2akey"] = w2aKey;
        params[@"app_name"] = [ud stringForKey:@"HM_AppName"] ?: @"";
    } else if (w2aKey.length == 0) {
        [self handleRequestCompletionForEid:params[@"eid"]];
    }
}

- (BOOL)isTimestampExpired:(NSString *)timestamp {
    NSTimeInterval interval = [timestamp doubleValue];
    return [[NSDate date] timeIntervalSince1970] - interval > 48 * 3600;
}

- (void)logRequest:(NSURLRequest *)request
            params:(NSString *)params
          response:(NSData *)responseData {
    if (!self.isEnableLog) return;
    NSMutableString *headerString = [NSMutableString string];
    [headerString appendFormat:@"URL: %@\n", request.URL.absoluteString];
    [headerString appendFormat:@"Method: %@\n", request.HTTPMethod];
    [headerString appendString:@"Headers:\n"];
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [headerString appendFormat:@"  %@: %@\n", key, value];
    }];
    NSString *responseStr = @"";
    if (responseData) {
        responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }
    HMLog(@"\n**************\n hm_event log \n\n%@\nRequestBody:\n%@\n\nResponse:\n%@\n**************\n\n"
    , headerString, params, responseStr);
}

- (NSDictionary *)processResponseData:(NSDictionary *)data {
    return [self recursiveFilterNullValues:data];
}

- (id)recursiveFilterNullValues:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *cleanDict = [NSMutableDictionary dictionary];
        [(NSDictionary *)object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id cleaned = [self recursiveFilterNullValues:obj];
            if (cleaned) cleanDict[key] = cleaned;
        }];
        return cleanDict.copy;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *cleanArray = [NSMutableArray array];
        [(NSArray *)object enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id cleaned = [self recursiveFilterNullValues:obj];
            if (cleaned) [cleanArray addObject:cleaned];
        }];
        return cleanArray.copy;
    }
    
    if ([object isKindOfClass:[NSNull class]]) return nil;
    return object;
}

#pragma mark - 公开接口
- (void)requestJsonPost:(NSString *)relativePath
                 params:(NSDictionary *)params
           successBlock:(HSResponseSuccessBlock)successBlock
              failBlock:(HSResponseFailBlock)failBlock {
    [self addRequestToQueueWithMethod:@"POST"
                         relativePath:relativePath
                               params:params
                         successBlock:successBlock
                            failBlock:failBlock];
}

- (void)requestJsonGet:(NSString *)relativePath
                params:(NSDictionary *)params
          successBlock:(HSResponseSuccessBlock)successBlock
             failBlock:(HSResponseFailBlock)failBlock {
    [self addRequestToQueueWithMethod:@"GET"
                         relativePath:relativePath
                               params:params
                         successBlock:successBlock
                            failBlock:failBlock];
}

- (void)setLogEnabled:(BOOL)isEnable {
    self.isEnableLog = isEnable;
}

@end
