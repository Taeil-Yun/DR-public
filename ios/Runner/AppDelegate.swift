import UIKit
import Flutter
import NaverThirdPartyLogin
import AppTrackingTransparency
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
//      FirebaseApp.configure()
      
    if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
      
     // 앱 추적 투명성
     if #available(iOS 14, *) {
         func requestPermission() {
             ATTrackingManager.requestTrackingAuthorization {
                 status in
                 switch status {
                 case .authorized:
                     print("we got permission")
                 case .notDetermined:
                     print("the user has not yet received an authorization request")
                 case .restricted:
                     print("the permission we get are restricted")
                 case .denied:
                     print("we didn't get the permission")
                 @unknown default:
                     print("looks like we didn't get permission")
                 }
             }
         }
         requestPermission()
     }
      
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  // naver login
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var applicationResult = false
        if (!applicationResult) {
            applicationResult = NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
        }
        // 다른 응용 프로그램 url 프로세스를 사용하는 경우 여기에 코드를 추가
        if (!applicationResult) {
            applicationResult = super.application(app, open: url, options: options)
        }
        return applicationResult
    }
}
