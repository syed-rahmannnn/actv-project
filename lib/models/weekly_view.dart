class WeeklyView {
  final String day;
  final int views;

  WeeklyView({required this.day, required this.views});

  factory WeeklyView.fromJson(Map<String, dynamic> json) {
    return WeeklyView(
      day: json['day']?.toString() ?? '',
      views: json['views'] is int
          ? json['views']
          : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'views': views};
  }
}
