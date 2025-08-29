//
//  OmniaApp.swift
//  Omnia
//
//  Created by George S Christopher on 17/08/25.
//

import SwiftUI
import UIKit

@main
struct OmniaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Enable background app refresh
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Register for background processing
        if #available(iOS 13.0, *) {
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        
        print("App launched with background refresh enabled")
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background fetch
        print("Background fetch triggered")
        
        // Perform your background tasks here
        // For example, send location data to server
        
        completionHandler(.newData)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
    }
}
