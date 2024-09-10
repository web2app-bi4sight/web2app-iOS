//
//  AppDelegate.swift
//  HM_Demo
//
//  Created by HM on 2024/09/10.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 打开hmlog，默认关闭。release包不打印数据
        hm.setLogEnabled(true)
        
        // S2S时需要注册这个block，非S2S可以不加
        hm.updateW2aDataEvent { advData, HM_W2a_Data in
            // 接收到W2A并发送到后台
//            print(HM_W2a_Data)
        }
        
        // 关联设备或者用户的唯一ID，可用于投放后与BI数据对齐。（当游客账号与正式账号无绑定关系时，不要传游客ID，避免造成后期数据对不齐的情况）
        hm.setDeviceID("IDFV||UserID||GuestID")
        
        // 判断App是首次安装并且是首次启动时，isNewUser=true; App版本更新和正常启动isNewUser=false。注意App从不包含HMSDK的版本升级到HMSDK的版本时，isNewUser=false
        let isinitHMB = UserDefaults.standard.string(forKey: "initHMB")
        var isNewUser = false
        if isinitHMB == nil || isinitHMB == "" {
            isNewUser = true
            UserDefaults.standard.set("initHMB", forKey: "initHMB")
            UserDefaults.standard.synchronize()
        }
        
        // 安装事件，回调为数组，数组内的数据为与落地页协定的deeplink数据。
        // SDK网关地址"https://cdn.bi4sight.com"。完成注册事件名为BI_CompleteRegistration。AppName需要传小写的。
        // appname为BI后台网关配置中的一致
        hm.`init`("https://cdn.bi4sight.com", installEventName: "BI_CompleteRegistration", isNewUser: isNewUser, appName: "demo") { array in
            if array?.count ?? 0 > 0 {
//                print("init----\(array)")
                // 跳转ID对应详情页 let idStr = array[1]
            } else {
//                print("array = nil")
            }
        }
        
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

