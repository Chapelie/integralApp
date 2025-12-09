/// Device information model for tracking device-specific data
///
/// This class stores information about the device running the IntegralPOS app,
/// which is crucial for offline-first sync and device identification.
library;

class DeviceInfo {
  final String deviceId;
  final String model;
  final String os;
  final String appVersion;
  final String locale;

  DeviceInfo({
    required this.deviceId,
    required this.model,
    required this.os,
    required this.appVersion,
    required this.locale,
  });

  /// Converts DeviceInfo to JSON map
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'model': model,
      'os': os,
      'appVersion': appVersion,
      'locale': locale,
    };
  }

  /// Creates DeviceInfo from JSON map
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      model: json['model'] as String,
      os: json['os'] as String,
      appVersion: json['appVersion'] as String,
      locale: json['locale'] as String,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, model: $model, os: $os, appVersion: $appVersion, locale: $locale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceInfo &&
        other.deviceId == deviceId &&
        other.model == model &&
        other.os == os &&
        other.appVersion == appVersion &&
        other.locale == locale;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^
        model.hashCode ^
        os.hashCode ^
        appVersion.hashCode ^
        locale.hashCode;
  }
}
