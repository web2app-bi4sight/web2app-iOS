//
//  HM_EventDataModel.m
//  HT_Test
//
//  Created by HM on 2024/09/24.
//

#import "HM_EventDataModel.h"

@interface HM_EventDataModel ()
@property (nonatomic, strong) NSString *oldEventID;  // 老eventID

@end

@implementation HM_EventDataModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.poid = @"";
        self.eventId = [self getGUID];
        self.oldEventID = @"";
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
    NSString *eid = @"";
    if ([self.eventId isEqualToString: self.oldEventID]) {
        self.eventId = [self getGUID];
    }
    self.oldEventID = self.eventId;
    eid = self.eventId ?: [self getGUID];
    return @{
        @"po_id": self.poid ?: @"",
        @"event_id": eid,
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
