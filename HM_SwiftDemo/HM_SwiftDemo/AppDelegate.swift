//
//  AppDelegate.swift
//  HM_SwiftDemo
//
//  Created by HM on 2024/08/13.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let web2app = HM_Web2App.sharedInstance()// 实例对象
        //控制台输出，默认关闭。release包自动关闭打印
        web2app.setLogEnabled(true)
        //首次启动传空值，非首次启动传入IDFV或IDFA均可
        web2app.deviceTrackID = ""
        //关联设备或者用户的唯一ID，可用于投放后与BI数据对齐。（当游客账号与正式账号无绑定关系时，不要传游客ID，避免造成后期数据对不齐的情况）
        web2app.uid = "IDFV||UserID||GuestID"
        web2app.delegate = self
        web2app.attibute(withAppname: "YouAppName")//初始化并归因，在前面的参数赋值完之后再执行
        
        return true
    }
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

extension AppDelegate : HM_Web2AppDelegate {
    func didReceiveHMData(_ data: [AnyHashable : Any]) {
        NSLog("%@", data)
        // 落地页传输的deeplink，用落地页协定的方式去解析，跳转到对应的页面或执行特定的操作
        let adv_data = data["adv_data"] as? [String] ?? []
        // 唯一识别ID，可用于与BI数据对齐
        let external_id = data["external_id"] as? String ?? ""
        // 0: w2a用户，1: w2a 老用户(被再次追踪到)， 2 :非w2a 追踪用户
        let user_type = data["user_type"] as? String ?? ""
        // 归因状态：false-归因失败，true-归因成功
        let isAttribution = (data["isAttribution"] as? Bool) ?? false
        // 归因模式：字符串，如果是来自剪切板归因，该属性为："cut"；其余为服务器归因；isAttribution==false时为空字符串
        let attribution_type = data["attribution_type"] as? String ?? ""
    }
}

