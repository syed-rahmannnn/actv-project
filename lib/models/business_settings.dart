class BusinessSettings {
  final String businessId;
  final bool publicProfile;
  final bool showProductsPublicly;
  final bool privateAnalytics;
  final bool notifyProfileViews;
  final bool notifyProductInquiries;
  final bool notifyWeeklySummary;

  BusinessSettings({
    required this.businessId,
    this.publicProfile = true,
    this.showProductsPublicly = true,
    this.privateAnalytics = false,
    this.notifyProfileViews = true,
    this.notifyProductInquiries = true,
    this.notifyWeeklySummary = true,
  });

  // Create from JSON
  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessId: json['businessId'] as String,
      publicProfile: json['publicProfile'] as bool? ?? true,
      showProductsPublicly: json['showProductsPublicly'] as bool? ?? true,
      privateAnalytics: json['privateAnalytics'] as bool? ?? false,
      notifyProfileViews: json['notifyProfileViews'] as bool? ?? true,
      notifyProductInquiries: json['notifyProductInquiries'] as bool? ?? true,
      notifyWeeklySummary: json['notifyWeeklySummary'] as bool? ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'publicProfile': publicProfile,
      'showProductsPublicly': showProductsPublicly,
      'privateAnalytics': privateAnalytics,
      'notifyProfileViews': notifyProfileViews,
      'notifyProductInquiries': notifyProductInquiries,
      'notifyWeeklySummary': notifyWeeklySummary,
    };
  }

  // Convert to JSON without businessId (for PUT requests)
  Map<String, dynamic> toJsonWithoutId() {
    return {
      'publicProfile': publicProfile,
      'showProductsPublicly': showProductsPublicly,
      'privateAnalytics': privateAnalytics,
      'notifyProfileViews': notifyProfileViews,
      'notifyProductInquiries': notifyProductInquiries,
      'notifyWeeklySummary': notifyWeeklySummary,
    };
  }

  // Copy with method for easy updates
  BusinessSettings copyWith({
    String? businessId,
    bool? publicProfile,
    bool? showProductsPublicly,
    bool? privateAnalytics,
    bool? notifyProfileViews,
    bool? notifyProductInquiries,
    bool? notifyWeeklySummary,
  }) {
    return BusinessSettings(
      businessId: businessId ?? this.businessId,
      publicProfile: publicProfile ?? this.publicProfile,
      showProductsPublicly: showProductsPublicly ?? this.showProductsPublicly,
      privateAnalytics: privateAnalytics ?? this.privateAnalytics,
      notifyProfileViews: notifyProfileViews ?? this.notifyProfileViews,
      notifyProductInquiries:
          notifyProductInquiries ?? this.notifyProductInquiries,
      notifyWeeklySummary: notifyWeeklySummary ?? this.notifyWeeklySummary,
    );
  }

  // Get default settings for a business
  static BusinessSettings defaults(String businessId) {
    return BusinessSettings(
      businessId: businessId,
      publicProfile: true,
      showProductsPublicly: true,
      privateAnalytics: false,
      notifyProfileViews: true,
      notifyProductInquiries: true,
      notifyWeeklySummary: true,
    );
  }
}
