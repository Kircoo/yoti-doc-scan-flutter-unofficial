import Flutter
import UIKit

import YotiSDKCore
import YotiSDKIdentityDocument
import YotiSDKSupplementaryDocument
import YotiSDKFaceTec
import YotiSDKFaceCapture

@main
@objc class AppDelegate: FlutterAppDelegate, YotiSDKDataSource, YotiSDKDelegate {
    var yotiChannel: FlutterMethodChannel?
    var yotiNavigationController: YotiSDKNavigationController?
    var sessionId: String?
    var sessionToken: String?
    
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        yotiChannel = FlutterMethodChannel(
            name: "mobile.yoti.com/docscan",
            binaryMessenger: controller.binaryMessenger
        )
        yotiChannel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "startDocScan" else {
                result(FlutterMethodNotImplemented)
                return
            }
            
            guard let arguments = call.arguments as? [String: Any],
                  let sessionId = arguments["sessionId"] as? String,
                  let sessionToken = arguments["sessionToken"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for startDocScan.",
                    details: nil
                ))
                return
            }
            
            self?.sessionId = sessionId
            self?.sessionToken = sessionToken
            self?.startDocScan(result: result)
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func startDocScan(result: @escaping FlutterResult) {
        guard let rootViewController = window?.rootViewController else {
            result(FlutterError(
                code: "UNAVAILABLE",
                message: "Root view controller not available.",
                details: nil
            ))
            return
        }
        
        if yotiNavigationController?.presentingViewController != nil {
            print("Yoti Doc Scan is already presented!")
            return
        }
        
        print("Session ID: \(sessionId ?? "")")
        print("Session Token: \(sessionToken ?? "")")
        
        yotiNavigationController = YotiSDKNavigationController()
        yotiNavigationController?.sdkDataSource = self
        yotiNavigationController?.sdkDelegate = self
        rootViewController.present(yotiNavigationController!, animated: true, completion: nil)
    }
    
    // MARK: - YotiSDKDataSource
    
    func supportedModuleTypes(for navigationController: YotiSDKNavigationController) -> [YotiSDKModule.Type] {
        [
            YotiSDKIdentityDocumentModule.self,
            YotiSDKSupplementaryDocumentModule.self,
            YotiSDKFaceTecModule.self,
            YotiSDKFaceCaptureModule.self
        ]
    }
    
    func sessionID(for navigationController: YotiSDKNavigationController) -> String {
        sessionId ?? ""
    }
    
    func sessionToken(for navigationController: YotiSDKNavigationController) -> String {
        sessionToken ?? ""
    }
    
    // MARK: - YotiSDKDelegate
    
    func navigationController(_ navigationController: YotiSDKNavigationController, didFinishWithResult result: YotiSDKResult) {
        guard let rootViewController = window?.rootViewController else {
            return
        }
        rootViewController.dismiss(animated: true)
        switch result {
        case .success:
            let docScanResult: [String: Any] = [
                "sessionStatusCode": 0,  // Set the success status code
                "sessionStatusDescription": "Success"
            ]
            self.yotiChannel?.invokeMethod("onYotiSdkResult", arguments: docScanResult)
        case .failure(let error):
            let errorCode = error.errorCode
            let errorDescription = error.localizedDescription
            
            let docScanResult: [String: Any] = [
                "sessionStatusCode": errorCode,
                "sessionStatusDescription": "Error: \(errorDescription)"
            ]
            self.yotiChannel?.invokeMethod("onYotiSdkResult", arguments: docScanResult)
        }
    }
}
