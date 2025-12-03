import 'weekly_view.dart';
import 'top_product_analytics.dart';

class AnalyticsOverview {
  final int profileViews;
  final int productViews;
  final int searchAppearances;
  final int connections;
  final int profileViewsChangePercent;
  final int productViewsChangePercent;
  final int searchAppearancesChangePercent;
  final int connectionsChangePercent;
  final List<WeeklyView> weeklyProfileViews;
  final List<TopProductAnalytics> topProducts;
  final String insightText;

  AnalyticsOverview({
    required this.profileViews,
    required this.productViews,
    required this.searchAppearances,
    required this.connections,
    required this.profileViewsChangePercent,
    required this.productViewsChangePercent,
    required this.searchAppearancesChangePercent,
    required this.connectionsChangePercent,
    required this.weeklyProfileViews,
    required this.topProducts,
    required this.insightText,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      profileViews: json['profileViews'] is int
          ? json['profileViews']
          : int.tryParse(json['profileViews']?.toString() ?? '0') ?? 0,
      productViews: json['productViews'] is int
          ? json['productViews']
          : int.tryParse(json['productViews']?.toString() ?? '0') ?? 0,
      searchAppearances: json['searchAppearances'] is int
          ? json['searchAppearances']
          : int.tryParse(json['searchAppearances']?.toString() ?? '0') ?? 0,
      connections: json['connections'] is int
          ? json['connections']
          : int.tryParse(json['connections']?.toString() ?? '0') ?? 0,
      profileViewsChangePercent: json['profileViewsChangePercent'] is int
          ? json['profileViewsChangePercent']
          : int.tryParse(
                  json['profileViewsChangePercent']?.toString() ?? '0',
                ) ??
                0,
      productViewsChangePercent: json['productViewsChangePercent'] is int
          ? json['productViewsChangePercent']
          : int.tryParse(
                  json['productViewsChangePercent']?.toString() ?? '0',
                ) ??
                0,
      searchAppearancesChangePercent:
          json['searchAppearancesChangePercent'] is int
          ? json['searchAppearancesChangePercent']
          : int.tryParse(
                  json['searchAppearancesChangePercent']?.toString() ?? '0',
                ) ??
                0,
      connectionsChangePercent: json['connectionsChangePercent'] is int
          ? json['connectionsChangePercent']
          : int.tryParse(json['connectionsChangePercent']?.toString() ?? '0') ??
                0,
      weeklyProfileViews:
          (json['weeklyProfileViews'] as List<dynamic>?)
              ?.map((item) => WeeklyView.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts:
          (json['topProducts'] as List<dynamic>?)
              ?.map(
                (item) =>
                    TopProductAnalytics.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      insightText: json['insightText']?.toString() ?? 'No insights available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileViews': profileViews,
      'productViews': productViews,
      'searchAppearances': searchAppearances,
      'connections': connections,
      'profileViewsChangePercent': profileViewsChangePercent,
      'productViewsChangePercent': productViewsChangePercent,
      'searchAppearancesChangePercent': searchAppearancesChangePercent,
      'connectionsChangePercent': connectionsChangePercent,
      'weeklyProfileViews': weeklyProfileViews.map((v) => v.toJson()).toList(),
      'topProducts': topProducts.map((p) => p.toJson()).toList(),
      'insightText': insightText,
    };
  }
}
