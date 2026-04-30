import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var blurView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(name: "com.hemanth.qwicktalk/security",
                                              binaryMessenger: controller.binaryMessenger)

    securityChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "secureScreen" {
        let enabled = call.arguments as! Bool
        if enabled {
            NotificationCenter.default.addObserver(self, selector: #selector(self.screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.didTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
        showBlurScreen()
    } else {
        hideBlurScreen()
    }
  }

  @objc func didTakeScreenshot() {
    showBlurScreen()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.hideBlurScreen()
    }
  }

  private func showBlurScreen() {
    if blurView == nil {
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView?.frame = window!.bounds
        window?.addSubview(blurView!)

        let label = UILabel()
        label.text = "Content Protected"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.frame = blurView!.bounds
        blurView?.contentView.addSubview(label)
    }
  }

  private func hideBlurScreen() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
