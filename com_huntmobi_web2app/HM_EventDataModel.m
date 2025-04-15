//
//  HM_EventDataModel.m
//  HM
//
//  Created by HM on 2025/04/01.
//

#import "HM_EventDataModel.h"
#import "HM_Config.h"

@interface HM_EventDataModel ()

@end

@implementation HM_EventDataModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.poid = @"";
        self.eventId = [[HM_Config sharedManager] getGUID];
        self.eventName = @"";
        self.currency = @"";
        self.value = @"";
        self.contentType = @"";
        self.contentIds = @[];
    }
    return self;
}

- (nonnull NSDictionary *)toDictionary {
    NSString *eid = self.eventId;
    NSString *eventTime = self.eventTime;
    self.eventId = @"";
    self.eventTime = @"";
    return @{
        @"po_id": self.poid ?: @"",
        @"event_id": eid.length > 0 ? eid : [[HM_Config sharedManager] getGUID],
        @"event_name": self.eventName ?: @"",
        @"currency": self.currency ?: @"",
        @"value": self.value ?: @"",
        @"content_type": self.contentType ?: @"",
        @"content_ids": self.contentIds ?: @[],
        @"event_time" : eventTime.length > 0 ? eventTime : [[HM_Config sharedManager] getTimestamp]
    };
}

@end
