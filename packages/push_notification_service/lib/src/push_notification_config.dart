/// Immutable configuration for [PushNotificationService].
class PushNotificationConfig {
  const PushNotificationConfig({
    this.requestPermissionsOnInit = true,
    this.showForegroundNotifications = true,
    this.androidNotificationChannelId = 'high_importance_channel',
    this.androidNotificationChannelName = 'High Importance Notifications',
    this.androidNotificationChannelDescription =
        'Used for important alerts and updates.',
    this.androidDefaultIcon = '@mipmap/ic_launcher',
    this.enableVerboseLogging = false,
  });

  /// Asks the OS for alert/badge/sound permission during [initialize].
  final bool requestPermissionsOnInit;

  /// When true, shows a system tray notification while the app is foregrounded
  /// (FCM does not display those automatically).
  final bool showForegroundNotifications;

  /// Android notification channel id (must stay stable across releases).
  final String androidNotificationChannelId;

  final String androidNotificationChannelName;
  final String androidNotificationChannelDescription;

  /// Drawable/mipmap used by Android local notifications.
  final String androidDefaultIcon;

  /// Prints debug logs from the package when true.
  final bool enableVerboseLogging;
}
