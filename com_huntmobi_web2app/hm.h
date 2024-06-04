//
//  HM.h
//  HM
//
//  Created by CCC on 2022/12/2.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

typedef void (^W2ABlock)(NSArray *ad_data, NSString *w2a_data);

@interface hm : NSObject

/**
 *是否开启WebView指纹，需要在hm.init前设置，默认为true
 */
+(void) useFingerPrinting:(BOOL) isEnable;

/**
 *  初始化传入相应参数，app启动时调用
 *
 *  @param Gateway  一个基于Https://开头加上域名构成的网关URL，不包含结尾的 /
 *  @param InstallEventName 完成注册的事件名称，如果不传默认为：CompleteRegistration
 *  @param IsNewUser 是否是新用户，新用户传true
 *
 */
+(void) init : (NSString *) Gateway InstallEventName : (NSString *)InstallEventName IsNewUser: (BOOL)IsNewUser AppName: (NSString *)AppName;

/**
 *  初始化传入相应参数，app启动时调用 -- 扩展，回调Adv_Data数组
 *
 *  @param IsNewUser 是否是新用户，新用户传true
 */
+(void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser: (BOOL)IsNewUser AppName: (NSString *)AppName success : (void(^)(NSArray * array))block;

/**
 *  购物事件上报
 *  @param nameStr  事件名称
 *  @param usdStr   货币符号
 *  @param valueStr 价格
 *  @param typeStr  单个商品可传“product”，多个商品可传"product_group"
 *  @param idsStr   商品ID字符串，多个商品ID用英文逗号（,）分割
 */
+(void) Purchase:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr;

/**
 *  自定义事件上报
 *
 *  @param nameStr  事件名称
 *  @param usdStr   货币符号
 *  @param valueStr 价格
 *  @param typeStr  单个商品可传“product”，多个商品可传"product_group"，可不传
 *  @param idsStr   商品ID字符串，多个商品ID用英文逗号（,）分割，可不传
 */
+(void) EventPost:(NSString *) nameStr Currency : (NSString *) usdStr Value : (NSString *) valueStr ContentType : (NSString *) typeStr ContentIds : (NSString *) idsStr;
 
/**
 *  修改用户信息
 *
 *  @param emStr  邮箱
 *  @param fbStr   Facebook
 *  @param idStr app用户ID
 *  @param phStr  电话号码
 */
+(void) UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr UserId : (NSString *) idStr Phone : (NSString *) phStr success : (void(^)(void))block;


/**
 *  修改用户信息--拓展
 *
 *  @param emStr  邮箱
 *  @param fbStr   Facebook
 *  @param idStr app用户ID
 *  @param phStr  电话号码
 *  @param zipcodeStr  邮编 使用小写字母，且不可包含空格和破折号。美国邮编只限使用前 5 位数。英国邮编请使用邮域 + 邮区 + 邮政部门格式。
 *  @param cityStr  城市 小写字母（移除所有空格） 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号、特殊字符和空格。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
 *  @param stateStr  州或省 , 以两个小写字母表示的州或省代码 使用 2 个字符的 ANSI 缩写代码 必须为小写字母。请使用小写字母对美国境外的州/省/自治区/直辖市名称作标准化处理，且不可包含标点符号、特殊字符和空格。
 *  @param genderStr  f 表示女性 m 表示男性
 *  @param fnStr  名字 - 不包含姓氏 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
 *  @param lnStr  姓氏 - 不包含名字 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
 *  @param dateBirthStr  出生年月 输入：2/16/1997 标准化格式：19970216 格式规则 YYYYMMDD
 *  @param countryStr  国家 请按照 ISO 3166-1 二位字母代码表示方式使用小写二位字母国家/地区代码。 输入：United States 准化格式：us
 */
+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr UserId : (NSString *) idStr Phone : (NSString *) phStr Zipcode : (NSString *) zipcodeStr City : (NSString *) cityStr State : (NSString *) stateStr Gender : (NSString *) genderStr Fn : (NSString *) fnStr Ln : (NSString *) lnStr DateBirth : (NSString *) dateBirthStr Country : (NSString *) countryStr success : (void(^)(void))block;


// 2.4去掉UserID字段
+ (void)UserDataUpdateEvent:(NSString *) emStr Fb_login_id : (NSString *) fbStr Phone : (NSString *) phStr Zipcode : (NSString *) zipcodeStr City : (NSString *) cityStr State : (NSString *) stateStr Gender : (NSString *) genderStr Fn : (NSString *) fnStr Ln : (NSString *) lnStr DateBirth : (NSString *) dateBirthStr Country : (NSString *) countryStr success : (void(^)(void))block;


/**
 *提供给APP读取落地页传递的字符串数组信息，如果没有则返回长度为0的数组
 */
+(NSArray *) AdvDataRead;

/**
 *请求数据打印开关 默认关闭
 */
+(void) setLogEnabled:(BOOL) isEnable;

/**
 *读取w2a加密数据
 */
+(NSString *) GetW2AEncrypt;

/**
 *修改w2a加密数据
 */
//+(void) SetW2AEncrypt : (NSString *) w2a_data;

/**
 * 获取归因信息
 *  IsAttribution  归因成功(获取到加密信息，表示归因成功）
 *  Attribution_type  归因模式:  字符串，如果是来自剪切板归因，该属性为："cut"，如果属性IsAttribution 为False 传入null
 *  External_id  唯一识别Id，如果属性IsAttribution 为False 传入null
 */
+(void)GetAttributionInfo : (void(^)(BOOL IsAttribution, NSString *Attribution_type, NSString *External_id, NSString *UserType))block;


+(void)UpdateW2aDataEvent : (void(^)(NSArray *ad_data, NSString *HM_W2a_Data))block;

/**
 *  2.1新增
 *  获取服务器最新Adv_Data
 */
+(void)GetPageData : (void(^)(NSArray *ad_data))block;



/**
 * 2.3更新
 *  购物事件上报
 *  @param eventName  事件名称
 *  @param currency   货币符号
 *  @param value 价格
 *  @param contentType  单个商品可传“product”，多个商品可传"product_group"
 *  @param contentIds   商品ID字符串，多个商品ID用英文逗号（,）分割
 *  @param po_id   付费订单Id , 服务器根据该ID , 标记唯一信息 , 过期时间48小时; 48小时内同样的ID 不再处理
 */
+(void) Purchase:(NSString *) eventName Currency : (NSString *) currency Value : (NSString *) value ContentType : (NSString *) contentType ContentIds : (NSString *) contentIds Po_Id : (NSString *)po_id;


/**
 * 2.4更新
 *  自定义事件上报
 *  @param eventID  事件ID，建议使用GUID确保唯一性，如果客户有自己的追踪的ID 时候，可以保持一致方便通过事件ID追踪数据链路，若无，可以给空字符串，SDK 将自己生成GUID；每次调用该函数将生成一个新的GUID；
 *  @param eventName  事件名称
 *  @param currency   货币符号
 *  @param value 价格
 *  @param contentType  单个商品可传“product”，多个商品可传"product_group"，可不传
 *  @param contentIds   商品ID字符串，多个商品ID用英文逗号（,）分割，可不传
 */
+(void) EventPost:(NSString *)eventID EventName : (NSString *) eventName Currency : (NSString *) currency Value : (NSString *) value ContentType : (NSString *) contentType ContentIds : (NSString *) contentIds;

/**
 * 2.4更新
 *  设置用户设备唯一标记
 *  @param deviceStr  事件名称
 */
+(void) SetDeviceID:(NSString *) deviceStr;



/**
 *  设置用户设备唯一标记
 *  @param
 */

///**
// *  2.5更新
// *  对剪切板有特殊需求时用的初始化方法，剪切板数据由APP端传入，SDK不再获取剪切板
// *
// *  @param ClipboardData 剪切板数据
// */
//+(void)init:(NSString *)Gateway InstallEventName:(NSString *)InstallEventName IsNewUser: (BOOL)IsNewUser AppName: (NSString *)AppName ClipboardData:(NSString *)ClipboardData  success : (void(^)(NSArray * array))block;



@end

//NS_ASSUME_NONNULL_END
