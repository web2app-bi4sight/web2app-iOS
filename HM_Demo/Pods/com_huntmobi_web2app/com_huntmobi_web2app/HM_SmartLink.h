//
//  hm.h
//  web2app
//
//  Created by HM on 2024/06/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_SmartLink : NSObject

@property (nonatomic, assign) BOOL isNewUser;
@property (nonatomic, copy) NSString *deviceTrackID;
@property (nonatomic, copy) NSString *codeString;
@property (nonatomic, copy) NSString *fromString;
@property (nonatomic, copy) NSArray *codesArray;

+ (instancetype)sharedInstance;

-(void) attibute : (NSDictionary *)dic  andBlock : (void(^)(NSDictionary * dic))block;

// 兼容web2app
-(void) attibuteBlock : (void(^)(NSDictionary * dic))block;

-(void) setSCodes:(NSString *)sCodes;

- (void)continueUserActivity:(NSUserActivity * _Nullable)userActivity;


@end

NS_ASSUME_NONNULL_END
