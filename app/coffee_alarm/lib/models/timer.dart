class TimerAlarm {
  final String coffeeType;
  final String time;

  TimerAlarm({required this.coffeeType, required this.time});

  factory TimerAlarm.fromJson(Map<String, dynamic> json) {
    return TimerAlarm(
      coffeeType: json['coffee'] as String,
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coffee': coffeeType,
      'time': time,
    };
  }
}