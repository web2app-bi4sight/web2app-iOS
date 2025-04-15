//
//  HM_EventDataModel.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_EventDataModel : NSObject

/**
 *  付费订单Id，第三方支付返回的订单id、账单id或流水id等唯一标识，可通过该id与后台用户数据匹配上。Purchase事件必传
 */
@property (nonatomic, copy) NSString *poid;

/**
 *  事件ID，建议使用GUID确保唯一性，如果客户有自己的追踪的ID 时，可以保持一致方便通过事件ID追踪数据链路，若无，可以给空字符串或不传值，SDK 将自己生成GUID；每次调用该函数将生成一个新的GUID；
 *  ——非必传
 */
@property (nonatomic, copy) NSString *eventId;

/**
 *  事件名称，推荐使用BI事件名，BI事件名兼容不同媒体平台。也可使用媒体平台标准事件名或自定义事件名
 */
@property (nonatomic, copy) NSString *eventName;

/**
 *  货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
 */
@property (nonatomic, copy) NSString *currency;

/**
 *  货币价值，使用浮点小数；如果传入非数字将强制默认为0
 */
@property (nonatomic, copy) NSString *value;

/**
 *  内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传product_group
 */
@property (nonatomic, copy) NSString *contentType;

/**
 *  内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
 */
@property (nonatomic, strong) NSArray<NSString *> *contentIds;

/**
 *  创建Model时已默认生成可不传。
 *  如Model创建为公用类则需重新赋最新的值，可调用Model的setTimestamp方法自动设置时间戳
 *  事件发生时间戳，取 UTC(0) 时区，秒级时间戳（10位）
 */
@property (nonatomic, copy) NSString *eventTime;

- (nonnull NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
