//
//  HM_EventInfoModel.m
//  HT_Test
//
//  Created by HM on 2024/09/24.
//

#import "HM_EventInfoModel.h"

@implementation HM_EventInfoModel

- (nonnull NSDictionary *)toDictionary {
    return @{
        @"is_event": @(self.isEventKey),
        @"is_delay": @(self.isDelay),
        @"event_data": [self.eventData toDictionary],
    };
}

@end
