class UserSettingsModel {
  final int? id;
  final String lastPeriodDate;
  final int cycleLength;
  final int periodDuration;

  UserSettingsModel({
    this.id,
    required this.lastPeriodDate,
    required this.cycleLength,
    required this.periodDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastPeriodDate': lastPeriodDate,
      'cycleLength': cycleLength,
      'periodDuration': periodDuration,
    };
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      id: map['id'],
      lastPeriodDate: map['lastPeriodDate'],
      cycleLength: map['cycleLength'],
      periodDuration: map['periodDuration'],
    );
  }
}
