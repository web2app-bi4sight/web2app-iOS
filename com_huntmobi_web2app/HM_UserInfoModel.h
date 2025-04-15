//
//  HM_UserInfoModel.h
//  HM
//
//  Created by HM on 2025/04/01.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HM_UserInfoModel : NSObject

/**
 *  邮箱，有则传入，无则空
 */
@property (nonatomic, copy) NSString *email;

/**
 *  FB登录ID，有则传入，无则传空
 */
@property (nonatomic, copy) NSString *fbLoginId;

/**
 *  电话号码，有则传入，无则留空
 */
@property (nonatomic, copy) NSString *phone;

/**
 *  国家 请按照 ISO 3166-1 二位字母代码表示方式使用小写二位字母国家/地区代码。
 */
@property (nonatomic, copy) NSString *country;

/**
 *   邮编 - 使用小写字母，且不可包含空格和破折号。美国邮编只限使用前 5 位数。英国邮编请使用邮域 + 邮区 + 邮政部门格式。
 */
@property (nonatomic, copy) NSString *zipCode;

/**
 *  城市 - 小写字母（移除所有空格）推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号、特殊字符和空格。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
 */
@property (nonatomic, copy) NSString *city;

/**
 *  州或省 , 以两个小写字母表示的州或省代码 - 使用 2 个字符的 ANSI 缩写代码，必须为小写字母。请使用小写字母对美国境外的州/省/自治区/直辖市名称作标准化处理，且不可包含标点符号、特殊字符和空格。
 */
@property (nonatomic, copy) NSString *state;

/**
 *  性别 - f 表示女性, m 表示男性
 */
@property (nonatomic, copy) NSString *gender;

/**
 *  名字 - 不包含姓氏 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码
 */
@property (nonatomic, copy) NSString *firstName;

/**
 *  姓氏 - 不包含名字 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
 */
@property (nonatomic, copy) NSString *lastName;

/**
 *  出生年月 - 输入：2/16/1997 标准化格式：19970216 格式规则 YYYYMMDD
 */
@property (nonatomic, copy) NSString *birthday;


- (nonnull NSDictionary *)toDictionary;

- (nonnull NSArray *)toArray;


@end

NS_ASSUME_NONNULL_END
