//
//  HM_EventInfoModel.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_EventInfoModel.h"
#import "HM_Config.h"

@implementation HM_EventInfoModel

- (nonnull NSDictionary *)toDictionary {
    return @{
        @"is_event": @(self.isEventKey),
        @"is_delay": @(self.isDelay),
        @"event_data": [self.eventData toDictionary],
    };
}


//eventId    事件id
//eventName    事件名称
//eventValue    事件值
//eventCurrency    事件货币单位
//eventTime    事件时间戳
//contentIds    内容 ID 列表
//poid    POID（可能是某种标识符）
//delay    是否延迟（布尔值，1 表示 true，其他值表示 false）
//keyEvent    是否是关键事件（布尔值，1 表示 true，其他值表示 false）
- (nonnull NSArray *)toArray{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.eventData.contentIds ?: @[] options:0 error:&error];
    NSString *jsonString = @"";
    if (error) {
        NSLog(@"Error serializing array to JSON: %@", error);
    } else {
        // 将 JSON 数据转化为字符串
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"JSON String: %@", jsonString);
    }
    return @[
        self.eventData.eventId,
        self.eventData.eventName,
        self.eventData.value ?: @"",
        self.eventData.currency ?: @"",
        self.eventData.eventTime.length > 0 ? self.eventData.eventTime : [[HM_Config sharedManager] getTimestamp],
        jsonString,
        self.eventData.poid ?: @"",
        @(self.isDelay),
        @(self.isEventKey)
    ];
}

@end
