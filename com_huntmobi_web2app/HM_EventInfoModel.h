//
//  HM_EventInfoModel.h
//  HT_Test
//
//  Created by HM on 2024/09/24.
//

#import <Foundation/Foundation.h>
#import "HM_EventDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HM_EventInfoModel : NSObject

/**
 *  是否是关键事件
 */
@property (nonatomic, assign) BOOL isEventKey;

/**
 *  是否需要延迟上报
 */
@property (nonatomic, assign) BOOL isDelay;

/**
 *  事件内容
 */
@property (nonatomic, strong) HM_EventDataModel *eventData;

- (nonnull NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
