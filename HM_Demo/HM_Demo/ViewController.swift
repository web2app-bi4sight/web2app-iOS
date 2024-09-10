//
//  ViewController.swift
//  HM_Demo
//
//  Created by HM on 2024/09/10.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 当用户数据发生变化时调用上报用户信息接口，供FB广告投放学习
        // 最优方案是通过FBSDK获取到以下相应的数据
        // 没有可传空字符串
        /**
         修改用户信息
         邮编：使用小写字母，且不可包含空格和破折号。美国邮编只限使用前 5 位数。英国邮编请使用邮域 + 邮区 + 邮政部门格式。
         城市： 小写字母（移除所有空格） 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号、特殊字符和空格。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
         州或省：以两个小写字母表示的州或省代码 使用 2 个字符的 ANSI 缩写代码 必须为小写字母。请使用小写字母对美国境外的州/省/自治区/直辖市名称作标准化处理，且不可包含标点符号、特殊字符和空格。
         性别： f 表示女性 m 表示男性
         名字： 不包含姓氏 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
         姓氏 ：不包含名字 推荐使用罗马字母字符 a 至 z。仅限小写字母，且不可包含标点符号。若使用特殊字符，则须按 UTF-8 格式对文本进行编码。
         出生年月： 输入：2/16/1997 标准化格式：19970216 格式规则 YYYYMMDD
         国家： 请按照 ISO 3166-1 二位字母代码表示方式使用小写二位字母国家/地区代码。 输入：United States 准化格式：us
         */
        hm.userDataUpdateEvent("获取到用户的邮箱",
                               fb_login_id: "用户使用登录Facebook时拿到的userid(没有可传空字符串)",
                               phone: "获取到用户的电话",
                               zipcode: "获取到用户的邮编",
                               city: "获取到用户的城市",
                               state: "获取到用户的省",
                               gender: "获取到用户的性别",
                               fn: "获取到用户的first name",
                               ln: "获取到用户的last name",
                               dateBirth: "获取到用户的生日",
                               country: "获取到用户的国家") {
            // 更新用户信息之后，在UserDataUpdateEvent的回调中，固定执行添加支付信息事件,事件名为BI_AddPaymentInfo，其余参数可传空
            hm.eventPost("", eventName: "BI_AddPaymentInfo", currency: "", value: "", contentType: "", contentIds: "")
        }
        
        // 当用户看完落地页对应的剧或小说的所有免费剧目或章节时，上报这个事件
        hm.eventPost("", // eventID--事件ID，需要确保唯一性，web2app的后台会做幂等性处理；可传空字符串，SDK默认会生成GUID上报。
                     eventName: "BI_AddToWishlist", // 固定事件名
                     currency: "", // 币种，无价值可传空字符串
                     value: "", // 价值，可传空字符串
                     contentType: "product_group", // 单集单章单个商品可传“product”，多个可传"product_group"
                     contentIds: "vid000001,vid000002,vid000003") // 单集单章单商品可传对应ID，多个可用英文逗号分隔传入一个完整字符串
                     
        
        // 当用户点击加入购物车按钮时触发
        hm.eventPost("", // eventID--事件ID需要确保唯一性，web2app的后台会做幂等性处理；可不传，SDK默认会生成GUID上报。
                     eventName: "BI_AddToCart", // 固定事件名
                     currency: "USD", // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
                     value: "9.99", // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
                     contentType: "product_group", // 单个商品可传“product”，多个可传"product_group"
                     contentIds: "p000001,v000002,d000003") // 单商品可传对应ID，多个可用英文逗号分隔传入一个完整字符串
        
        // 当用户点击付款按钮时触发
        hm.eventPost("", // eventID--事件ID需要确保唯一性，web2app的后台会做幂等性处理；可不传，SDK默认会生成GUID上报。
                     eventName: "BI_InitiateCheckout", // 固定事件名
                     currency: "USD", // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
                     value: "9.99", // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
                     contentType: "product_group", // 单集单章单个商品可传“product”，多个可传"product_group"
                     contentIds: "p000001,v000002,d000003") // 单集单章单商品可传对应ID，多个可用英文逗号分隔传入一个完整字符串
        
        // 用户支付完成后上报这个事件
        hm.purchase("BI_Purchase", // 固定事件名
                    currency: "USD", // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
                    value: "9.99", // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
                    contentType: "", // 单集单章单个商品可传“product”，多个可传"product_group"
                    contentIds: "", // 单集单章单商品可传对应ID，多个可用英文逗号分隔传入一个完整字符串
                    po_Id: "") // 三方支付返回的付费订单Id, 服务器根据该ID标记唯一信息，过期时间48小时；48小时内同样的ID 不再处理；强约束不考虑其他，如果为空或空字符串时候，忽略去重
                    
        
        // 当用户进入商品详情页时，上报这个事件
        hm.eventPost("", // eventID--事件ID需要确保唯一性，web2app的后台会做幂等性处理；可不传，SDK默认会生成GUID上报。
                     eventName: "BI_ProductView", // 固定事件名
                     currency: "", // 币种，无价值可传空字符串
                     value: "", // 价值，可传空字符串
                     contentType: "product", // 可传“product”
                     contentIds: "pid000001") // 商品对应ID
        
        // 当用户订阅某套餐或项目时，上报这个事件
        hm.eventPost("", // eventID--事件ID需要确保唯一性，web2app的后台会做幂等性处理；可不传，SDK默认会生成GUID上报。
                     eventName: "BI_Subscribe", // 固定事件名
                     currency: "USD", // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
                     value: "9.99", // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
                     contentType: "product", // 单可传“product”
                     contentIds: "p000001") // 可传对应ID
        
        //只统计次数，可在BI上看到
        hm.eventKey("");//传参为事件ID，需要确保唯一性，web2app的后台会做幂等性处理；可不传，SDK默认会生成GUID上报。

    }


}

