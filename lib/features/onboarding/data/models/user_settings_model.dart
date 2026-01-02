class UserSettingsModel {
  final int? id;
  final String lastPeriodDate;
  final int cycleLength;
  final int periodDuration;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final String reminderTime; // Stored as "HH:mm"

  UserSettingsModel({
    this.id,
    required this.lastPeriodDate,
    required this.cycleLength,
    required this.periodDuration,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 1,
    this.reminderTime = "09:00",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastPeriodDate': lastPeriodDate,
      'cycleLength': cycleLength,
      'periodDuration': periodDuration,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore,
      'reminderTime': reminderTime,
    };
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      id: map['id'],
      lastPeriodDate: map['lastPeriodDate'],
      cycleLength: map['cycleLength'],
      periodDuration: map['periodDuration'],
      reminderEnabled: map['reminderEnabled'] == 1,
      reminderDaysBefore: map['reminderDaysBefore'] ?? 1,
      reminderTime: map['reminderTime'] ?? "09:00",
    );
  }
}
