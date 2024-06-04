//
//  HM.m
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import "hm.h"
#import "HM_NetWork.h"
#import "HM_Config.h"
#import "GetWebViewInfo.h"

@implementation hm

static W2ABlock w2aBlock;


+ (void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser:(BOOL)IsNewUser AppName:(NSString *)AppName {
    if (Gateway.length < 1) {
        return;
    }
    [[HM_Config sharedManager] saveDeviceID];
    [[HM_Config sharedManager] saveBaseInfo];

    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@[] forKey:@"HM_Adv_Data"];
    [userDefaults setObject:AppName forKey:@"HM_App_Name"];

//    [userDefaults setObject:Gateway.length > 0 ? Gateway : @"https://capi.bi4sight.com" forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:Gateway forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:InstallEventName.length > 0 ? InstallEventName : @"CompleteRegistration" forKey:@"HM_InstallEventName"];// 完成注册的事件名称，如果不传默认为：CompleteRegistration
    NSString *isFirst = [userDefaults objectForKey:@"HM_isFirstInsert"];
    if (!IsNewUser) { //  不是第一次安装
        NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
        if (HM_W2a_Data.length > 0) { // 是web2App用户
            [hm reuqestOnattibute:AppName success:^{
                [hm updataInfo];
                [hm requestErrorPurchaseEvent];
                [hm requestErrorEventPost];
            }];
        } else {
            [hm reuqestOnattibute:AppName success:^{
               
            }];
        }
    } else {
        if ([isFirst isEqual: @"0"]) { //  不是第一次安装
            NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
            if (HM_W2a_Data.length > 0) { // 是web2App用户
                [hm reuqestOnattibute:AppName success:^{
                    [hm updataInfo];
                    [hm requestErrorPurchaseEvent];
                    [hm requestErrorEventPost];
                }];
            } else {
                [hm reuqestOnattibute:AppName success:^{
                   
                }];
            } // 不是则无操作
        } else { //  第一次安装
            [userDefaults setObject:@"0" forKey:@"HM_isFirstInsert"];
            NSString *copyString = [[UIPasteboard generalPasteboard] string];
            if (copyString.length > 0) { //
                NSString *preStr = @"w2a_data:";
                BOOL result = [copyString hasPrefix:preStr];
                if (result) {// 剪切板有包含w2a_data:开头的数据
                    [userDefaults setObject:copyString forKey:@"HM_W2a_Data"];
                    [userDefaults setObject:@"cut" forKey:@"HM_Attribution_Type"];
                    [userDefaults setBool:true forKey:@"HM_IsAttribution"];
                    [userDefaults setObject:@"0" forKey:@"HM_User_Type"];
                    // 调用网关【新装API】，并将获取到的adv_data[]写入本地
                    [hm requestNewUser];
                } else { // 无符合条件数据
                    [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                    [hm getWebViewInfo:AppName];
                }
            } else {
                [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                [hm getWebViewInfo:AppName];
            }
        }
    }
    [userDefaults synchronize];
}

+ (void)getWebViewInfo: (NSString *) AppName {
    [[GetWebViewInfo shared] creatWebView:^(NSString * _Nonnull string) {
        [hm reuqestRegisterInfo:AppName];
    }];
}

//MARK: 调用网关 【落地页信息读取API】，判断是否是落地页用户
+ (void)reuqestRegisterInfo: (NSString *) AppName{
    /*  调用网关 【落地页信息读取API】，判断是否是落地页用户
        读取：存本地，以后调别的API都要用到该信息
        读取：调用网关【新装API】，并将获取到的adv_data[]写入本地
        读不到：标记非新安装（写本地信息）
    */
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/landingpageread", Gateway];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{}];
    [dic setObject:AppName forKey:@"app_name"];
    NSString *jsonString = [userDefaults objectForKey:@"HM_WebView_Fingerprint"];
    if (jsonString.length > 0) {
        NSDictionary *d = [[HM_Config sharedManager] dictionaryWithJsonString:jsonString];
        [dic setObject:[d objectForKey:@"ca"] forKey:@"ca"];
        [dic setObject:[d objectForKey:@"wg"] forKey:@"wg"];
        [dic setObject:[d objectForKey:@"pi"] forKey:@"pi"];
        [dic setObject:[d objectForKey:@"ao"] forKey:@"ao"];
        [dic setObject:[d objectForKey:@"se"] forKey:@"se"];
        [dic setObject:[d objectForKey:@"ft"] forKey:@"ft"];
        [dic setObject:[d objectForKey:@"ua"] forKey:@"ua"];
    }
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Info"];
    [dic setObject:device_info forKey:@"device_info"];
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            NSString *external_id = data[@"external_id"];
            NSString *attribution_type = data[@"attribution_type"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults setObject:external_id forKey:@"HM_External_Id"];
            [userDefaults setObject:attribution_type forKey:@"HM_Attribution_Type"];
            if (w2a_data_encrypt.length > 0) {
                [userDefaults setBool:true forKey:@"HM_IsAttribution"];
            } else {
                [userDefaults setBool:false forKey:@"HM_IsAttribution"];
            }
            [userDefaults synchronize];
            if (w2a_data_encrypt.length > 0) {
                [hm requestNewUser];
            }
        }
    } failBlock:^(NSError * _Nonnull error) {
        
    }];
}

//MARK: 调用网关【新装API】，并将获取到的adv_data[]写入本地
+ (void)requestNewUser {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/oninstall", Gateway];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Info"];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSString *event_name = [userDefaults objectForKey:@"HM_InstallEventName"];
    NSString *event_id = [hm getGUID];
    NSDictionary *dic = @{@"device_info" : device_info,
                          @"device_id" : device_id,
                          @"customData" : @{@"event_name" : event_name, @"event_id" : event_id, @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]},
                          @"w2a_data_encrypt" : w2a_data_encrypt};
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSArray *adv_data = data[@"adv_data"];
            NSString *external_id = data[@"external_id"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            NSString *user_type = data[@"user_type"];
            [userDefaults setObject:user_type forKey:@"HM_User_Type"];
            [userDefaults setObject:adv_data forKey:@"HM_Adv_Data"];
            [userDefaults setObject:external_id forKey:@"HM_External_Id"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults synchronize];
        }
    } failBlock:^(NSError * _Nonnull error) {
        
    }];

}

//MARK: 调用网关【会话API】上报信息
+ (void)updataInfo {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/onsession", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt} successBlock:^(NSDictionary * _Nonnull responseObject) {
        
    } failBlock:^(NSError * _Nonnull error) {
        
    }];
    
}

//MARK: 调用【网关购物API】，上报&由网关转发购物事件
+ (void)Purchase:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/onpurchase", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSMutableDictionary *custom_data = [NSMutableDictionary dictionaryWithDictionary:@{
        @"event_name" : nameStr.length > 0 ? nameStr : @"Purchase",
        @"currency" : usdStr.length > 0 ? usdStr : @"USD",
        @"value" : valueStr.length > 0 ? valueStr : @"0.00",
        @"event_id" : [hm getGUID],
        @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
    }];
    if (typeStr.length > 0) {
        [custom_data setObject:typeStr forKey:@"content_type"];
        if (idsStr.length > 0) {
            NSArray *idsArray = [idsStr componentsSeparatedByString:@","];
            if (idsArray.count > 0) {
                [custom_data setObject:idsArray forKey:@"content_ids"];
            }
        }
    }
    [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:custom_data], @"po_id" : @""} successBlock:^(NSDictionary * _Nonnull responseObject) {
        
    } failBlock:^(NSError * _Nonnull error) {
        if (error.code == -1001) {
            [hm saveErrorPurchaseEvent:custom_data poid:@""];
        }
    }];
}

//MARK: 调用【网关购物API】，上报&由网关转发购物事件
+ (void)Purchase:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr Po_Id:(NSString *)po_id{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/onpurchase", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSMutableDictionary *custom_data = [NSMutableDictionary dictionaryWithDictionary:@{
        @"event_name" : nameStr.length > 0 ? nameStr : @"Purchase",
        @"currency" : usdStr.length > 0 ? usdStr : @"USD",
        @"value" : valueStr.length > 0 ? valueStr : @"0.00",
        @"event_id" : [hm getGUID],
        @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
    }];
    if (typeStr.length > 0) {
        [custom_data setObject:typeStr forKey:@"content_type"];
        if (idsStr.length > 0) {
            NSArray *idsArray = [idsStr componentsSeparatedByString:@","];
            if (idsArray.count > 0) {
                [custom_data setObject:idsArray forKey:@"content_ids"];
            }
        }
    }
    [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:custom_data], @"po_id" : po_id} successBlock:^(NSDictionary * _Nonnull responseObject) {
        
    } failBlock:^(NSError * _Nonnull error) {
        if (error.code == -1001) {
            [hm saveErrorPurchaseEvent:custom_data poid:po_id];
        }
    }];
}

//MARK: 调用网关【EventPost（转发API）】，上报&由网关转发自定义事件
+ (void)EventPost:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/eventpost", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSMutableDictionary *custom_data = [NSMutableDictionary dictionaryWithDictionary:@{
        @"event_name" : nameStr.length > 0 ? nameStr : @"Purchase",
        @"currency" : usdStr.length > 0 ? usdStr : @"USD",
        @"value" : valueStr.length > 0 ? valueStr : @"0.00",
        @"event_id" : [hm getGUID],
        @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
    }];
    if (typeStr.length > 0) {
        [custom_data setObject:typeStr forKey:@"content_type"];
    }
    if (idsStr.length > 0) {
        NSArray *idsArray = [idsStr componentsSeparatedByString:@","];
        if (idsArray.count > 0) {
            [custom_data setObject:idsArray forKey:@"content_ids"];
        }
    }
    [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:custom_data]} successBlock:^(NSDictionary * _Nonnull responseObject) {
        
    } failBlock:^(NSError * _Nonnull error) {
        if (error.code == -1001) {
            [hm saveErrorEventPost:custom_data];
        }
    }];
}

+(void) EventPost:(NSString *)eventID EventName : (NSString *) eventName Currency : (NSString *) currency Value : (NSString *) value ContentType : (NSString *) contentType ContentIds : (NSString *) contentIds{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/eventpost", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSMutableDictionary *custom_data = [NSMutableDictionary dictionaryWithDictionary:@{
        @"event_name" : eventName.length > 0 ? eventName : @"AddToCart",
        @"currency" : currency.length > 0 ? currency : @"USD",
        @"value" : value.length > 0 ? value : @"0.00",
        @"event_id" :eventID.length > 0 ? eventID : [hm getGUID],
        @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]
    }];
    if (contentType.length > 0) {
        [custom_data setObject:contentType forKey:@"content_type"];
    }
    if (contentIds.length > 0) {
        NSArray *idsArray = [contentIds componentsSeparatedByString:@","];
        if (idsArray.count > 0) {
            [custom_data setObject:idsArray forKey:@"content_ids"];
        }
    }
    [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:custom_data]} successBlock:^(NSDictionary * _Nonnull responseObject) {
        
    } failBlock:^(NSError * _Nonnull error) {
        if (error.code == -1001) {
            [hm saveErrorEventPost:custom_data];
        }
    }];
}

//MARK: 调用网关【UserDataUpdate（用户信息更新API）】
+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr UserId : (NSString *) idStr Phone : (NSString *) phStr success:(nonnull void (^)(void))block{
    NSString *em = emStr;
    NSString *fb_login_id = fbStr;
    NSString *external_id = idStr;
    NSString *ph = phStr;
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/userdataupdate", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSDictionary *dic = @{@"device_id" : device_id,
                          @"w2a_data_encrypt" : w2a_data_encrypt,
                          @"em" : em,
                          @"fb_login_id" : fb_login_id,
                          @"external_id" : external_id,
                          @"ph" : ph
    };
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
//            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
//            [userDefaults synchronize];
            [hm isSendW2A:w2a_data_encrypt];
        }
        block();
    } failBlock:^(NSError * _Nonnull error) {
        block();
    }];
}

 
+(NSArray *)AdvDataRead {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
//    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
//    if (w2a_data_encrypt.length < 1){
//        return @[];
//    }
//    NSArray *adv_Data = [userDefaults objectForKey:@"HM_Adv_Data"];
//    return adv_Data.count > 0 ? adv_Data : @[];
    id adv_Data = [userDefaults objectForKey:@"HM_Adv_Data"];
    if ([adv_Data isKindOfClass:[NSArray class]]) {
        return adv_Data;
    } else {
        return @[];
    }
}

+(void)setLogEnabled:(BOOL)isEnable {
    [[HM_NetWork shareInstance] setLogEnabled:isEnable];
}

+(void) requestErrorPurchaseEvent {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSArray *array = [userDefaults objectForKey:@"HM_Erroe_Purchase"];
    NSArray *poidArray = [userDefaults objectForKey:@"HM_Erroe_Purchase_Poid"];
    if (array.count > 0) {
        NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
        if (w2a_data_encrypt.length < 1){
            return;
        }
        NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
        if (Gateway.length < 1) {
            return;
        }
        NSString *url = [NSString stringWithFormat:@"%@/onpurchase", Gateway];
        NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
        NSDictionary *dic = array[0];
        NSMutableArray *mArray = [NSMutableArray arrayWithArray:array];
        [mArray removeObjectAtIndex:0];
        [userDefaults setObject:mArray forKey:@"HM_Erroe_Purchase"];
        NSString * poid = @"";
        if (poidArray.count > 0) {
            poid = poidArray[0];
            NSMutableArray *mArray1 = [NSMutableArray arrayWithArray:poidArray];
            [mArray1 removeObjectAtIndex:0];
        }
        
        
        [userDefaults synchronize];
        [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:dic], @"po_id" : poid} successBlock:^(NSDictionary * _Nonnull responseObject) {
            [hm requestErrorPurchaseEvent];
        } failBlock:^(NSError * _Nonnull error) {
            if (error.code == -1001) {
                [hm saveErrorPurchaseEvent:dic poid:poid];
            }
        }];
    }
    
}

+(void) saveErrorPurchaseEvent:(NSDictionary *) custom_data poid : (NSString *) poid {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSMutableArray * mArray = [NSMutableArray arrayWithArray: [userDefaults objectForKey:@"HM_Erroe_Purchase"]];
    NSMutableArray * mArray1 = [NSMutableArray arrayWithArray: [userDefaults objectForKey:@"HM_Erroe_Purchase_Poid"]];

    [mArray addObject:custom_data];
    [mArray1 addObject:poid];

    [userDefaults setObject:mArray forKey:@"HM_Erroe_Purchase"];
    [userDefaults setObject:mArray1 forKey:@"HM_Erroe_Purchase_Poid"];

    [userDefaults synchronize];
}

+(void) requestErrorEventPost {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSArray *array = [userDefaults objectForKey:@"HM_Erroe_EventPost"];
    if (array.count > 0) {
        NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
        if (w2a_data_encrypt.length < 1){
            return;
        }
        NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
        if (Gateway.length < 1) {
            return;
        }
        NSString *url = [NSString stringWithFormat:@"%@/eventpost", Gateway];
        NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
        NSDictionary *dic = array[0];
        NSString *nameStr = dic[@"event_name"];

        NSMutableArray *mArray = [NSMutableArray arrayWithArray:array];
        [mArray removeObjectAtIndex:0];
        [userDefaults setObject:mArray forKey:@"HM_Erroe_EventPost"];
        [userDefaults synchronize];

        [[HM_NetWork shareInstance] requestJsonPost:url params:@{@"device_id" : device_id, @"w2a_data_encrypt" : w2a_data_encrypt, @"custom_data" : [NSDictionary dictionaryWithDictionary:dic], @"event_name" : nameStr.length > 0 ? nameStr : @"Purchase"} successBlock:^(NSDictionary * _Nonnull responseObject) {
            [hm requestErrorEventPost];
        } failBlock:^(NSError * _Nonnull error) {
            if (error.code == -1001) {
                [hm saveErrorEventPost:dic];
            }
        }];
    }

}

+(void) saveErrorEventPost:(NSDictionary *) custom_data {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSMutableArray * mArray = [NSMutableArray arrayWithArray: [userDefaults objectForKey:@"HM_Erroe_EventPost"]];
    [mArray addObject:custom_data];
    [userDefaults setObject:mArray forKey:@"HM_Erroe_EventPost"];
    [userDefaults synchronize];
}


//MARK: 调用网关【UserDataUpdate（用户信息更新API）】--扩展
+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr UserId : (NSString *) idStr Phone : (NSString *) phStr Zipcode : (NSString *) zipcodeStr City : (NSString *) cityStr State : (NSString *) stateStr Gender : (NSString *) genderStr Fn : (NSString *) fnStr Ln : (NSString *) lnStr DateBirth : (NSString *) dateBirthStr Country : (NSString *) countryStr success:(nonnull void (^)(void))block {
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/userdataupdate", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSDictionary *dic = @{@"device_id" : device_id,
                          @"w2a_data_encrypt" : w2a_data_encrypt,
                          @"em" : emStr,
                          @"fb_login_id" : fbStr,
                          @"external_id" : idStr,
                          @"ph" : phStr,
                          @"zp" : zipcodeStr,
                          @"ct" : cityStr,
                          @"st" : stateStr,
                          @"ge" : genderStr,
                          @"fn" : fnStr,
                          @"ln" : lnStr,
                          @"db" : dateBirthStr,
                          @"country" : countryStr,
    };
    
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults synchronize];
        }
        block();
    } failBlock:^(NSError * _Nonnull error) {
        block();
    }];
}

+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr Phone : (NSString *) phStr Zipcode : (NSString *) zipcodeStr City : (NSString *) cityStr State : (NSString *) stateStr Gender : (NSString *) genderStr Fn : (NSString *) fnStr Ln : (NSString *) lnStr DateBirth : (NSString *) dateBirthStr Country : (NSString *) countryStr success:(nonnull void (^)(void))block {
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/userdataupdate", Gateway];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSDictionary *dic = @{@"device_id" : device_id,
                          @"w2a_data_encrypt" : w2a_data_encrypt,
                          @"em" : emStr,
                          @"fb_login_id" : fbStr,
                          @"ph" : phStr,
                          @"zp" : zipcodeStr,
                          @"ct" : cityStr,
                          @"st" : stateStr,
                          @"ge" : genderStr,
                          @"fn" : fnStr,
                          @"ln" : lnStr,
                          @"db" : dateBirthStr,
                          @"country" : countryStr,
    };
    
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults synchronize];
        }
        block();
    } failBlock:^(NSError * _Nonnull error) {
        block();
    }];
}


+ (void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser:(BOOL)IsNewUser AppName:(NSString *)AppName success : (void(^)(NSArray * array))successBlock {
    if (Gateway.length < 1) {
        successBlock(NULL); //网关为空，直接给null (空对象)
        return;
    }
    [[HM_Config sharedManager] saveDeviceID];
    [[HM_Config sharedManager] saveBaseInfo];

    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@[] forKey:@"HM_Adv_Data"];
    [userDefaults setObject:AppName forKey:@"HM_App_Name"];

//    [userDefaults setObject:Gateway.length > 0 ? Gateway : @"https://capi.bi4sight.com" forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:Gateway forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:InstallEventName.length > 0 ? InstallEventName : @"CompleteRegistration" forKey:@"HM_InstallEventName"];// 完成注册的事件名称，如果不传默认为：CompleteRegistration
    NSString *isFirst = [userDefaults objectForKey:@"HM_isFirstInsert"];
    if (!IsNewUser) { //  不是第一次安装
        NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
        if (HM_W2a_Data.length > 0) { // 是web2App用户
            [hm reuqestOnattibute:AppName success:^{
                [hm updataInfo];
                [hm requestErrorPurchaseEvent];
                [hm requestErrorEventPost];
                successBlock([hm AdvDataRead]);
            }];
        } else { // 不是则回调空对象
//            successBlock(NULL); //非w2a 用户,直接给null (空对象)
            [hm reuqestOnattibute:AppName success:^{
                successBlock([hm AdvDataRead]);
            }];
        }
    } else { // 判断 第一次安装
        if ([isFirst isEqual: @"0"]) {
            NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
            if (HM_W2a_Data.length > 0) { // 是web2App用户
                [hm reuqestOnattibute:AppName success:^{
                    [hm updataInfo];
                    [hm requestErrorPurchaseEvent];
                    [hm requestErrorEventPost];
                    successBlock([hm AdvDataRead]);
                }];
            } else { // 不是则回调空对象
//                successBlock(NULL); //非w2a 用户,直接给null (空对象)
                [hm reuqestOnattibute:AppName success:^{
                    successBlock([hm AdvDataRead]);
                }];
            }
        } else {
            [userDefaults setObject:@"0" forKey:@"HM_isFirstInsert"];
            BOOL isNeedRequest = true;
            NSString *copyString = [[UIPasteboard generalPasteboard] string];
            if (copyString.length > 0) { //
                NSString *preStr = @"w2a_data:";
                BOOL result = [copyString hasPrefix:preStr];
                if (result) {// 剪切板有包含w2a_data:开头的数据
                    [userDefaults setObject:copyString forKey:@"HM_W2a_Data"];
                    [userDefaults setObject:@"cut" forKey:@"HM_Attribution_Type"];
                    [userDefaults setBool:true forKey:@"HM_IsAttribution"];
                    [userDefaults setObject:@"0" forKey:@"HM_User_Type"];
                    // 调用网关【新装API】，并将获取到的adv_data[]写入本地
                    isNeedRequest = false;
                    [hm requestNewUser:^(NSArray *array) {
                        successBlock(array);
                    }];
                } else { // 无符合条件数据
                    isNeedRequest = false;
                    [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                    [hm getWebViewInfo : AppName success:^(NSArray *array) {
                        successBlock(array);
                    }];
                }
            } else {
                isNeedRequest = false;
                [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                [hm getWebViewInfo : AppName success:^(NSArray *array) {
                    successBlock(array);
                }];
            }
            if (isNeedRequest) {
                [hm getWebViewInfo : AppName success:^(NSArray *array) {
                    successBlock(array);
                }];
            }
        }
    }
    [userDefaults synchronize];
}

+ (void)getWebViewInfo : (NSString *) AppName success : (void(^)(NSArray * array))block  {
    [[GetWebViewInfo shared] creatWebView:^(NSString * _Nonnull string) {
        [hm reuqestRegisterInfo : AppName success :^(NSArray *array) {
            block(array);
        }];
    }];
}


//MARK: 调用网关 【落地页信息读取API】，判断是否是落地页用户 -- 带block
+ (void)reuqestRegisterInfo : (NSString *) AppName success : (void(^)(NSArray * array))block {
    /*  调用网关 【落地页信息读取API】，判断是否是落地页用户
        读取：存本地，以后调别的API都要用到该信息
        读取：调用网关【新装API】，并将获取到的adv_data[]写入本地
        读不到：标记非新安装（写本地信息）
    */
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/landingpageread", Gateway];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{}];
    [dic setObject:AppName forKey:@"app_name"];
    NSString *jsonString = [userDefaults objectForKey:@"HM_WebView_Fingerprint"];
    if (jsonString.length > 0) {
        NSDictionary *d = [[HM_Config sharedManager] dictionaryWithJsonString:jsonString];
        [dic setObject:[d objectForKey:@"ca"] forKey:@"ca"];
        [dic setObject:[d objectForKey:@"wg"] forKey:@"wg"];
        [dic setObject:[d objectForKey:@"pi"] forKey:@"pi"];
        [dic setObject:[d objectForKey:@"ao"] forKey:@"ao"];
        [dic setObject:[d objectForKey:@"se"] forKey:@"se"];
        [dic setObject:[d objectForKey:@"ft"] forKey:@"ft"];
        [dic setObject:[d objectForKey:@"ua"] forKey:@"ua"];
    }
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Info"];
    [dic setObject:device_info forKey:@"device_info"];
    
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            NSString *external_id = data[@"external_id"];
            NSString *attribution_type = data[@"attribution_type"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults setObject:external_id forKey:@"HM_External_Id"];
            [userDefaults setObject:attribution_type forKey:@"HM_Attribution_Type"];
            if (w2a_data_encrypt.length > 0) {
                [userDefaults setBool:true forKey:@"HM_IsAttribution"];
            } else {
                [userDefaults setBool:false forKey:@"HM_IsAttribution"];
            }
            [userDefaults synchronize];
            if (w2a_data_encrypt.length > 0) {
                [hm requestNewUser:^(NSArray *array) {
                    block(array);
                }];
            } else {
                block(@[]);
            }
        } else {
            block(@[]);
        }
    } failBlock:^(NSError * _Nonnull error) {
        block(@[]);
    }];
}

//MARK: 调用网关【新装API】，并将获取到的adv_data[]写入本地 -- 带block
+ (void)requestNewUser : (void(^)(NSArray * array))block {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (w2a_data_encrypt.length < 1){
        return;
    }
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/oninstall", Gateway];
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Info"];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSString *event_name = [userDefaults objectForKey:@"HM_InstallEventName"];
    NSString *event_id = [hm getGUID];
    NSDictionary *dic = @{@"device_info" : device_info,
                          @"device_id" : device_id,
                          @"customData" : @{@"event_name" : event_name, @"event_id" : event_id, @"event_time" : [[HM_Config sharedManager] currentUTCTimestamp]},
                          @"w2a_data_encrypt" : w2a_data_encrypt};
    [[HM_NetWork shareInstance] requestJsonPost:url params:dic successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSArray *adv_data = data[@"adv_data"];
            NSString *external_id = data[@"external_id"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            NSString *user_type = data[@"user_type"];
            [userDefaults setObject:user_type forKey:@"HM_User_Type"];
            [userDefaults setObject:adv_data forKey:@"HM_Adv_Data"];
            [userDefaults setObject:external_id forKey:@"HM_External_Id"];
            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults synchronize];
            block(adv_data);
        } else {
            block(@[]);
        }
    } failBlock:^(NSError * _Nonnull error) {
        block(@[]);
    }];

}


+(void)useFingerPrinting:(BOOL)isEnable {
    [[GetWebViewInfo shared] useFingerPrinting:isEnable];
}


+(NSString *) GetW2AEncrypt {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
    return  HM_W2a_Data;
}

+(void) SetW2AEncrypt : (NSString *) w2a_data {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:w2a_data forKey:@"HM_W2a_Data"];
    [userDefaults synchronize];
}

+(void) GetAttributionInfo:(void (^)(BOOL, NSString *, NSString *, NSString *))block{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *external_id = [userDefaults objectForKey:@"HM_External_Id"];
    NSString *attribution_type = [userDefaults objectForKey:@"HM_Attribution_Type"];
    BOOL IsAttribution = [userDefaults boolForKey:@"HM_IsAttribution"];
    NSString *user_type = [userDefaults objectForKey:@"HM_User_Type"];
    if (IsAttribution) {
        block(IsAttribution, attribution_type, external_id, user_type);
    } else {// IsAttribution 为False 传入null
        block(IsAttribution, @"", external_id, user_type);
    }
}


//MARK:
+ (void)reuqestOnattibute : (NSString *) AppName success : (void(^)(void))block{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/onattibute", Gateway];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{}];
    [dic setObject:AppName forKey:@"app_name"];
    NSString *jsonString = [userDefaults objectForKey:@"HM_WebView_Fingerprint"];
    if (jsonString.length > 0) {
        NSDictionary *d = [[HM_Config sharedManager] dictionaryWithJsonString:jsonString];
        [dic setObject:[d objectForKey:@"ca"] forKey:@"ca"];
        [dic setObject:[d objectForKey:@"wg"] forKey:@"wg"];
        [dic setObject:[d objectForKey:@"pi"] forKey:@"pi"];
        [dic setObject:[d objectForKey:@"ao"] forKey:@"ao"];
        [dic setObject:[d objectForKey:@"se"] forKey:@"se"];
        [dic setObject:[d objectForKey:@"ft"] forKey:@"ft"];
        [dic setObject:[d objectForKey:@"ua"] forKey:@"ua"];
    }
    
    NSDictionary *device_info = [userDefaults objectForKey:@"HM_Device_Info"];
    NSDictionary *device_id = [userDefaults objectForKey:@"HM_Device_Id"];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    NSDictionary *d = @{@"device_info" : device_info,
                          @"device_id" : device_id,
                          @"fingerprint_data" : dic,
                        @"w2a_data_encrypt" : w2a_data_encrypt.length > 0 ? w2a_data_encrypt : @""};
    
    [[HM_NetWork shareInstance] requestJsonPost:url params:d successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSString *w2a_data_encrypt = data[@"w2a_data_encrypt"];
            NSString *external_id = data[@"external_id"];
            NSString *user_type = data[@"user_type"];
            NSArray *adv_data = data[@"adv_data"];
//            [userDefaults setObject:w2a_data_encrypt forKey:@"HM_W2a_Data"];
            [userDefaults setObject:external_id forKey:@"HM_External_Id"];
            [userDefaults setObject:user_type forKey:@"HM_User_Type"];
            [userDefaults setObject:adv_data forKey:@"HM_Adv_Data"];
            [userDefaults synchronize];
            [hm isSendW2A:w2a_data_encrypt];
        }
        block();
    } failBlock:^(NSError * _Nonnull error) {
        block();
    }];
}

+ (void)UpdateW2aDataEvent:(W2ABlock)block {
    if (w2aBlock == nil) {
        w2aBlock = [block copy];
    }
    [hm sendW2A];
}


+ (void)isSendW2A : (NSString *)w2a {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    if (![w2a isEqualToString:w2a_data_encrypt]) {
        [userDefaults setObject:w2a forKey:@"HM_W2a_Data"];
        [userDefaults synchronize];
        [hm sendW2A];
    }
}

+ (void)sendW2A{
    if (w2aBlock == nil) {
        return;
    }
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *w2a_data_encrypt = [userDefaults objectForKey:@"HM_W2a_Data"];
    w2aBlock([hm AdvDataRead], w2a_data_encrypt);
}

+(NSString *)getGUID{
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

+ (void)GetPageData:(void (^)(NSArray *))block {
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *Gateway = [userDefaults objectForKey:@"HM_Gateway"];
    if (Gateway.length < 1) {
        block(@[]);
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/reloadpagedata", Gateway];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{}];
    NSString *AppName = [userDefaults objectForKey:@"HM_App_Name"];
    [dic setObject:AppName forKey:@"app_name"];
    NSString *jsonString = [userDefaults objectForKey:@"HM_WebView_Fingerprint"];
    if (jsonString.length > 0) {
        NSDictionary *d = [[HM_Config sharedManager] dictionaryWithJsonString:jsonString];
        [dic setObject:[d objectForKey:@"ca"] forKey:@"ca"];
        [dic setObject:[d objectForKey:@"wg"] forKey:@"wg"];
        [dic setObject:[d objectForKey:@"pi"] forKey:@"pi"];
        [dic setObject:[d objectForKey:@"ao"] forKey:@"ao"];
        [dic setObject:[d objectForKey:@"se"] forKey:@"se"];
        [dic setObject:[d objectForKey:@"ft"] forKey:@"ft"];
        [dic setObject:[d objectForKey:@"ua"] forKey:@"ua"];
    }
    NSDictionary *d = @{
                          @"fingerprint_data" : dic
                        };
    [[HM_NetWork shareInstance] requestJsonPost:url params:d successBlock:^(NSDictionary * _Nonnull responseObject) {
        NSString *code = [responseObject[@"code"] stringValue];
        if ([code isEqual: @"0"]) {
            NSDictionary *data = responseObject[@"data"];
            NSArray *adv_data = data[@"adv_data"];
            [userDefaults setObject:adv_data forKey:@"HM_Adv_Data"];
            [userDefaults synchronize];
            block([hm AdvDataRead]);
        } else {
            block(@[]);
        }
    } failBlock:^(NSError * _Nonnull error) {
        block(@[]);
    }];
}

+(void) SetDeviceID:(NSString *) string{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId = string;
    if (deviceId.length > 50) {
        deviceId = [deviceId substringToIndex:50];
    }
    [userDefaults setObject:deviceId forKey:@"__hm_uuid__"];
    [userDefaults synchronize];
}


+ (void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser:(BOOL)IsNewUser AppName:(NSString *)AppName ClipboardData:(NSString *)ClipboardData success : (void(^)(NSArray * array))successBlock {
    if (Gateway.length < 1) {
        successBlock(NULL); //网关为空，直接给null (空对象)
        return;
    }
    [[HM_Config sharedManager] saveDeviceID];
    [[HM_Config sharedManager] saveBaseInfo];

    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@[] forKey:@"HM_Adv_Data"];
    [userDefaults setObject:AppName forKey:@"HM_App_Name"];

//    [userDefaults setObject:Gateway.length > 0 ? Gateway : @"https://capi.bi4sight.com" forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:Gateway forKey:@"HM_Gateway"];// 一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
    [userDefaults setObject:InstallEventName.length > 0 ? InstallEventName : @"CompleteRegistration" forKey:@"HM_InstallEventName"];// 完成注册的事件名称，如果不传默认为：CompleteRegistration
    NSString *isFirst = [userDefaults objectForKey:@"HM_isFirstInsert"];
    if (!IsNewUser) { //  不是第一次安装
        NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
        if (HM_W2a_Data.length > 0) { // 是web2App用户
            [hm reuqestOnattibute:AppName success:^{
                [hm updataInfo];
                [hm requestErrorPurchaseEvent];
                [hm requestErrorEventPost];
                successBlock([hm AdvDataRead]);
            }];
        } else { // 不是则回调空对象
//            successBlock(NULL); //非w2a 用户,直接给null (空对象)
            [hm reuqestOnattibute:AppName success:^{
                successBlock([hm AdvDataRead]);
            }];
        }
    } else { // 判断 第一次安装
        if ([isFirst isEqual: @"0"]) {
            NSString *HM_W2a_Data = [userDefaults objectForKey:@"HM_W2a_Data"];
            if (HM_W2a_Data.length > 0) { // 是web2App用户
                [hm reuqestOnattibute:AppName success:^{
                    [hm updataInfo];
                    [hm requestErrorPurchaseEvent];
                    [hm requestErrorEventPost];
                    successBlock([hm AdvDataRead]);
                }];
            } else { // 不是则回调空对象
//                successBlock(NULL); //非w2a 用户,直接给null (空对象)
                [hm reuqestOnattibute:AppName success:^{
                    successBlock([hm AdvDataRead]);
                }];
            }
        } else {
            [userDefaults setObject:@"0" forKey:@"HM_isFirstInsert"];
            BOOL isNeedRequest = true;
            if (ClipboardData.length > 0) { //
                NSString *preStr = @"w2a_data:";
                BOOL result = [ClipboardData hasPrefix:preStr];
                if (result) {// 剪切板有包含w2a_data:开头的数据
                    [userDefaults setObject:ClipboardData forKey:@"HM_W2a_Data"];
                    [userDefaults setObject:@"cut" forKey:@"HM_Attribution_Type"];
                    [userDefaults setBool:true forKey:@"HM_IsAttribution"];
                    [userDefaults setObject:@"0" forKey:@"HM_User_Type"];
                    // 调用网关【新装API】，并将获取到的adv_data[]写入本地
                    isNeedRequest = false;
                    [hm requestNewUser:^(NSArray *array) {
                        successBlock(array);
                    }];
                } else { // 无符合条件数据
                    isNeedRequest = false;
                    [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                    [hm getWebViewInfo : AppName success:^(NSArray *array) {
                        successBlock(array);
                    }];
                }
            } else {
                isNeedRequest = false;
                [userDefaults setObject:@"2" forKey:@"HM_User_Type"];
                [hm getWebViewInfo : AppName success:^(NSArray *array) {
                    successBlock(array);
                }];
            }
            if (isNeedRequest) {
                [hm getWebViewInfo : AppName success:^(NSArray *array) {
                    successBlock(array);
                }];
            }
        }
    }
    [userDefaults synchronize];
}

@end
