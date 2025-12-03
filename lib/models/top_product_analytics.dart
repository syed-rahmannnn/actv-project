class TopProductAnalytics {
  final String name;
  final int views;
  final int engagement; // percent

  TopProductAnalytics({
    required this.name,
    required this.views,
    required this.engagement,
  });

  factory TopProductAnalytics.fromJson(Map<String, dynamic> json) {
    return TopProductAnalytics(
      name: json['name']?.toString() ?? 'Unknown Product',
      views: json['views'] is int
          ? json['views']
          : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      engagement: json['engagement'] is int
          ? json['engagement']
          : int.tryParse(json['engagement']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'views': views, 'engagement': engagement};
  }
}
