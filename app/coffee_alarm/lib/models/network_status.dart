class NetworkStatus {
  final String? configuredSsid;
  final bool isHotspotActive;
  final String? wlan0Ip;
  final String message;

  NetworkStatus({
    this.configuredSsid,
    required this.isHotspotActive,
    this.wlan0Ip,
    required this.message,
  });

  factory NetworkStatus.fromJson(Map<String, dynamic> json) {
    return NetworkStatus(
      configuredSsid: json['configured_ssid'] as String?,
      isHotspotActive: json['is_hotspot_active'] as bool,
      wlan0Ip: json['wlan0_ip'] as String?,
      message: json['message'] as String,
    );
  }
}