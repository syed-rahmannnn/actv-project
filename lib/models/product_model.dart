class Product {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String category;
  final double price;
  final String priceUnit;
  final String currency;
  final bool featured;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.priceUnit,
    required this.currency,
    required this.featured,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'Other',
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: json['priceUnit'] ?? 'one-time',
      currency: json['currency'] ?? 'INR',
      featured: json['featured'] ?? false,
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'priceUnit': priceUnit,
      'currency': currency,
      'featured': featured,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  /// Get formatted price with currency symbol
  String get displayPrice {
    final symbol = currency == 'INR' ? '₹' : '\$';
    final priceStr = price.toStringAsFixed(
      price.truncateToDouble() == price ? 0 : 2,
    );

    switch (priceUnit) {
      case 'monthly':
        return '$symbol$priceStr/mo';
      case 'hourly':
        return '$symbol$priceStr/hr';
      case 'yearly':
        return '$symbol$priceStr/yr';
      case 'one-time':
      default:
        return '$symbol$priceStr';
    }
  }

  /// Get user-friendly category name
  String get displayCategory {
    switch (category) {
      case 'Software':
        return 'Software';
      case 'Services':
        return 'Services';
      case 'Education':
        return 'Education';
      case 'Product':
        return 'Product';
      case 'Other':
      default:
        return 'Other';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'ACTIVE':
        return 'green';
      case 'OUT_OF_STOCK':
        return 'orange';
      case 'INACTIVE':
      default:
        return 'grey';
    }
  }

  /// Copy with method for updates
  Product copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? category,
    double? price,
    String? priceUnit,
    String? currency,
    bool? featured,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      currency: currency ?? this.currency,
      featured: featured ?? this.featured,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
