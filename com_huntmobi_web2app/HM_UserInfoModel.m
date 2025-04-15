//
//  HM_UserInfoModel.m
//  HM
//
//  Created by HM on 2025/04/01.
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


//facebookLoginId    Facebook 登录 ID
//Email    电子邮件地址
//Phone    电话号码
//PostalCode    邮政编码
//City    城市
//State    州/省
//Gender    性别
//FirstName    名字
//LastName    姓氏
//DateBirth    出生日期
//Country    国家
- (nonnull NSArray *)toArray {
    return @[
        self.fbLoginId ?: @"",
        self.email ?: @"",
        self.phone ?: @"",
        self.zipCode ?: @"",
        self.city ?: @"",
        self.state ?: @"",
        self.gender ?: @"",
        self.firstName ?: @"",
        self.lastName ?: @"",
        self.birthday ?: @"",
        self.country ?: @""
    ];
}

@end
