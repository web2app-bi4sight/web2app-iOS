//
//  HM_NetWork.h
//  HM
//
//  Created by CCC on 2022/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_NetWork : NSObject

+ (instancetype)shareInstance;

//请求URL
@property (nonatomic, copy) NSString *requestURL;

@property (nonatomic, assign) BOOL isEnableLog;

typedef void(^HSResponseSuccessBlock)(NSDictionary *responseObject);

typedef void(^HSResponseFailBlock)(NSError *error);

/**
 * @brief   JSON格式网络接口请求方法
 *
 * @param relativePath 接口名称
 * @param params 请求参数
 * @param successBlock 请求成功回调
 * @param failBlock 请求失败回调
 */
- (void)requestJsonPost:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock;

-(void) setLogEnabled:(BOOL) isEnable;

@end

NS_ASSUME_NONNULL_END
