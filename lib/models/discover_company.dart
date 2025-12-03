class DiscoverCompany {
  final String id;
  final String name;
  final String tagline;
  final String category;
  final String location;
  final int productsCount;
  final bool isVerified;
  final String? logoUrl;
  final String? area;

  DiscoverCompany({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.location,
    required this.productsCount,
    required this.isVerified,
    this.logoUrl,
    this.area,
  });

  factory DiscoverCompany.fromJson(Map<String, dynamic> json) {
    return DiscoverCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Company',
      tagline: json['tagline']?.toString() ?? 'No description available',
      category: json['category']?.toString() ?? 'Uncategorized',
      location: json['location']?.toString() ?? 'Location not specified',
      productsCount: json['productsCount'] is int
          ? json['productsCount']
          : int.tryParse(json['productsCount']?.toString() ?? '0') ?? 0,
      isVerified: json['isVerified'] == true,
      logoUrl: json['logoUrl']?.toString(),
      area: json['area']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'category': category,
      'location': location,
      'productsCount': productsCount,
      'isVerified': isVerified,
      'logoUrl': logoUrl,
      'area': area,
    };
  }
}
