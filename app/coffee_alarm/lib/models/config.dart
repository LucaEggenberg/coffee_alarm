class AppConfig {
  final int coffeeDurationSeconds;
  final int espressoDurationSeconds;

  AppConfig({required this.coffeeDurationSeconds, required this.espressoDurationSeconds});

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      coffeeDurationSeconds: json['coffee_duration_seconds'] as int,
      espressoDurationSeconds: json['espresso_duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coffee_duration_seconds': coffeeDurationSeconds,
      'espresso_duration_seconds': espressoDurationSeconds,
    };
  }
}