//
//  AppDelegate.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import UserNotifications

import IQKeyboardManager
import Firebase
import CoreLocation
import GoogleMaps
import SVProgressHUD

func IS_PAD() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    let locationManager = CLLocationManager()
    var lastPublishedLocation:CLLocation?
    let threshold:CLLocationDistance = 10.0

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Register_for_notifications
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            UNUserNotificationCenter.current().delegate = self
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Use Firebase library to configure APIs
        FIRApp.configure()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        
        FIRAuth.auth()?.addStateDidChangeListener({ auth, user in
            if let token = FIRInstanceID.instanceID().token(), let currentUser = auth.currentUser {
                Model.shared.publishToken(currentUser, token:token)
            }
        })
        
        // Facebook SDK init
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // UI settings

        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setBackgroundColor(UIColor.mainColor())
        SVProgressHUD.setForegroundColor(UIColor.white)

        UIApplication.shared.statusBarStyle = .lightContent
        if let font = UIFont(name: "HelveticaNeue-CondensedBold", size: 17) {
            UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName : font], for: .normal)
            SVProgressHUD.setFont(font)
        }
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        
        // connect iWatch
        _ = WatchManager.shared.activate()

        // Initialize Google Maps
        GMSServices.provideAPIKey(GoolgleMapAPIKey)
        
        // Location manager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.allowsBackgroundLocationUpdates = true
            if CLLocationManager.authorizationStatus() != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            } else {
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.startUpdatingLocation()
            }
        }
        
        return true
    }
    
    // MARK: - Receive_message
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
    }
    
    // MARK: - Refresh_token
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            connectToFcm()
            if let user = FIRAuth.auth()?.currentUser {
                Model.shared.publishToken(user, token: refreshedToken)
            }
        }
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
            FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
        #else
            FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.prod)
        #endif
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme! == FACEBOOK_SCHEME {
            return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        } else {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication: options[.sourceApplication] as! String!,
                                                     annotation: options[.annotation])
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    // MARK: - Split view
    
    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if splitViewController.isCollapsed {
            var secondViewController:UIViewController? = vc as? UINavigationController
            if secondViewController != nil {
                secondViewController = (secondViewController as! UINavigationController).topViewController
            } else {
                secondViewController = vc
            }
            
            if let master = splitViewController.viewControllers[0] as? UINavigationController {
                master.pushViewController(secondViewController!, animated: true)
            }
            return true
        } else {
            return false
        }
    }
    
    func application(_ application: UIApplication, handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?, reply: @escaping ([AnyHashable : Any]?) -> Void) {
        
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        // Print full message.
        print(userInfo)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        // Print full message.
        print(userInfo)
    }
}

extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}

extension AppDelegate : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if lastPublishedLocation == nil || lastPublishedLocation!.distance(from: location) > threshold {
                if Model.shared.publishCoordinate(location.coordinate) {
                    print("updated location")
                    lastPublishedLocation = location
                }
            }
        }
    }
}
