//
//  HM_EventDataModel.m
//  HT_Test
//
//  Created by HM on 2024/09/24.
//

#import "HM_EventDataModel.h"

@implementation HM_EventDataModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.poid = @"";
        self.eventId = [self getGUID];
        self.eventName = @"";
        self.currency = @"";
        self.value = @"";
        self.contentType = @"";
        self.contentIds = @[];
        [self setTimestamp];
    }
    
    return self;
}

- (nonnull NSDictionary *)toDictionary {
    return @{
        @"po_id": self.poid ?: @"",
        @"event_id": self.eventId ?: [self getGUID],
        @"event_name": self.eventName ?: @"",
        @"currency": self.currency ?: @"",
        @"value": self.value ?: @"",
        @"content_type": self.contentType ?: @"",
        @"content_ids": self.contentIds ?: @[],
        @"event_time" : self.eventTime
    };
}

- (void) setTimestamp {
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *timeStampString = [NSString stringWithFormat:@"%.0f", timeStamp];
    self.eventTime = timeStampString;
}

-(NSString *)getGUID{
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

@end
