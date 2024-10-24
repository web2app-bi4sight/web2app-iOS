//
//  ViewController.swift
//  HM_SwiftDemo
//
//  Created by HM on 2024/08/13.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    @IBAction func send(_ sender: Any) {
        self.userDataUpdate()
        self.addToWishlist()
        self.addToCart()
        self.initiateCheckout()
        self.purchase()
        self.subscribe()
        self.viewcontent()
        self.keyevent()
    }
    
    func userDataUpdate () {
        //当用户数据发生变化时调用上报用户信息接口，供FB广告投放学习
        //最优方案是通过FBSDK获取到以下相应的数据
        //没有可传空字符串，获取到任意值均可上报，可重复上报
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
        //email、fbLoginId、phone是重要字段，尽可能传入； 其余字段获取不到传空或不传，可以的话还是尽量传入
        let userInfoModel = HM_UserInfoModel()
        userInfoModel.email = "获取到用户的邮箱"
        userInfoModel.fbLoginId = "用户使用登录Facebook时拿到的userid(没有可传空字符串)"
        userInfoModel.phone = "获取到用户的电话"
        userInfoModel.country = "获取到用户的国家"
        userInfoModel.zipCode = "获取到用户的邮编"
        userInfoModel.city = "获取到用户的城市"
        userInfoModel.state = "获取到用户的省"
        userInfoModel.gender = "获取到用户的性别"
        userInfoModel.firstName = "获取到用户的名"
        userInfoModel.lastName = "获取到用户的姓"
        userInfoModel.birthday = "获取到用户的生日"
        //上报事件
        HM_Web2App.sharedInstance().updateUserInfo(userInfoModel)
    }
    
    func addToWishlist() {
        // 当用户看完落地页对应的剧或小说时，上报这个事件
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_AddToWishlist"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型，传入product
        eventDataModel.contentType = "product"
        // 内容编号，传入推广剧ID，在归因接口会返回
        eventDataModel.contentIds = ["vid100001"]

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func addToCart () {
        // 当用户点击加入购物车按钮时触发
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_AddToCart"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "9.99"
        // 内容类型，传入product
        eventDataModel.contentType = "product_group"
        //内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["vid100001", "p000001", "d000003"]

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func initiateCheckout() {
        // 当用户点击付款按钮时触发
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_InitiateCheckout"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传多个product_group
        eventDataModel.contentType = "product_group"
        // 内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["vid100001", "p000001", "d000003"]

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func purchase() {
        // 用户支付完成后上报这个事件
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_Purchase"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传多个product_group
        eventDataModel.contentType = "product_group"
        // 内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["vid100001", "p000001", "d000003"]
        // 付费订单Id，第三方支付返回的订单id、账单id或流水id等唯一标识，Purchase事件必传
        eventDataModel.poid = "p1234567890"

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = true
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func viewcontent() {
        // 当用户进入商品详情页时，上报这个事件
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_ProductView"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传多个product_group
        eventDataModel.contentType = "product"
        // 内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["pid000001"]

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func subscribe() {
        // 当用户订阅某套餐或项目成功后，上报这个事件
        // 事件具体内容
        let eventDataModel = HM_EventDataModel()
        // 事件名，推荐使用BI事件流对应的事件名称
        eventDataModel.eventName = "BI_Subscribe"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传多个product_group
        eventDataModel.contentType = "product"
        // 内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["vid100001"]

        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)

        // 在订阅事件上报之后，需要再次上报一个付费事件，用于投放时做数据对齐
        eventDataModel.eventName = "BI_Purchase"
        // 货币单位，使用国际标准货币代码，如：USD，代表美元；INR 代表印度卢比
        eventDataModel.currency = "USD"
        // 货币价值，使用浮点小数；如果传入非数字将强制默认为0
        eventDataModel.value = "1.99"
        // 内容类型(商品、剧、小说、礼包、套餐等)，单个传product，传多个product_group
        eventDataModel.contentType = "product"
        // 内容编号，content_type=product时，Id数组只能传入一个Id，若是使用content_type=product_group时，Id可以传入多个
        eventDataModel.contentIds = ["vid100001"]
        // 付费订单Id，第三方支付返回的订单id、账单id或流水id等唯一标识，Purchase事件必传
        eventDataModel.poid = "p1111234567890"

        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = true
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = false
        // 事件具体内容
        eventInfoModel.eventData = eventDataModel

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
    
    func keyevent() {
        // 只统计次数，可在BI上看到
        let eventInfoModel = HM_EventInfoModel()
        // 是否延迟上报，目前只有购物事件可以开启，如另有需要可以联系技术支持
        eventInfoModel.isDelay = false
        // 是否是关键事件，关键事件不上报媒体，只在BI统计
        eventInfoModel.isEventKey = true
        // 事件具体内容，关键事件不需要事件内容，可传可不传，只在BI后台统计并显示次数
        eventInfoModel.eventData = HM_EventDataModel()

        // 上报事件
        HM_Web2App.sharedInstance().eventPost(withEventInfo: eventInfoModel)
    }
}

