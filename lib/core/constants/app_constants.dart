// App-wide constants

class AppConstants {
  // UI
  static const double defaultPadding = 16.0;
  static const double sectionPadding = 20.0;
  static const double borderRadius = 20.0;
  static const double cardRadius = 18.0;
  static const double avatarRadiusSm = 22.0;
  static const double avatarRadiusMd = 30.0;
  static const double avatarRadiusLg = 50.0;

  // BLE
  static const double proximityTriggerMeters = 3.0;
  static const int proximityDebounceMinutes = 5;
  static const double txPowerDefault = -59.0;
  static const int rssiSmoothingWindow = 5;

  // Stories
  static const int storyExpiryHours = 24;
  static const int videoMaxSeconds = 10;

  // Chat
  static const int chatPageSize = 50;

  // XP
  static const int xpPerConnection = 10;
  static const int xpPerStory = 5;
  static const int xpPerProximityMatch = 2;
}
