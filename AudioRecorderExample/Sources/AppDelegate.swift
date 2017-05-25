//
//  AppDelegate.swift
//  AudioRecorderExample
//
//  Created by Clay on 5/25/17.
//  Copyright © 2017 Clay Ellis. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = ViewController()
        window!.makeKeyAndVisible()
        
        return true
    }

}

