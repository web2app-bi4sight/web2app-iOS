//
//  HM_UserInfoModel.m
//  HT_Test
//
//  Created by HM on 2024/09/26.
//

#import "HM_UserInfoModel.h"

@implementation HM_UserInfoModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.email = @"";
        self.fbLoginId = @"";
        self.phone = @"";
        self.country = @"";
        self.zipCode = @"";
        self.city = @"";
        self.state = @"";
        self.gender = @"";
        self.firstName = @"";
        self.lastName = @"";
        self.birthday = @"";
    }
    return self;
}

- (nonnull NSDictionary *)toDictionary {
    
    return @{
        @"em": self.email ?: @"",
        @"fb_login_id": self.fbLoginId ?: @"",
        @"ph": self.phone ?: @"",
        @"country": self.country ?: @"",
        @"zp": self.zipCode ?: @"",
        @"ct": self.city ?: @"",
        @"st": self.state ?: @"",
        @"ge": self.gender ?: @"",
        @"fn": self.firstName ?: @"",
        @"ln": self.lastName ?: @"",
        @"db": self.birthday ?: @"",
    };
}

@end
