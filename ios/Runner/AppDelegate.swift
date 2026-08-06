import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Tag used to find the secure UITextField we attach for capture protection.
  private static let secureFieldTag = 9_101_701

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register early so video-call protect/unprotect works as soon as Flutter runs.
    let channel = FlutterMethodChannel(
      name: "com.qobo1live.live/screen_capture_guard",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        DispatchQueue.main.async { self?.enableSecureScreen() }
        result(true)
      case "disable":
        DispatchQueue.main.async { self?.disableSecureScreen() }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Screen capture guard (1:1 video calls)

  /// Blanks screenshots / recordings of the app window (iOS limitation vs Android FLAG_SECURE).
  private func enableSecureScreen() {
    guard let window = keyWindow else { return }
    // Already protected.
    if window.viewWithTag(Self.secureFieldTag) != nil { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.tag = Self.secureFieldTag
    field.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(field)
    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: window.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: window.centerYAnchor),
      field.widthAnchor.constraint(equalToConstant: 1),
      field.heightAnchor.constraint(equalToConstant: 1),
    ])

    // Classic secure-layer trick: nest the window layer under the secure field layer
    // so system captures show a black frame instead of call content.
    if let secureContainer = field.layer.sublayers?.first {
      window.layer.superlayer?.addSublayer(secureContainer)
      secureContainer.addSublayer(window.layer)
    }
  }

  /// Removes the secure field so normal screenshots work again.
  private func disableSecureScreen() {
    guard let window = keyWindow else { return }
    window.viewWithTag(Self.secureFieldTag)?.removeFromSuperview()
  }

  private var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }
}
