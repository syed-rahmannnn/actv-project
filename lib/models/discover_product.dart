class DiscoverProduct {
  final String id;
  final String name;
  final String companyName;
  final String category;
  final double price;
  final String priceUnit;
  final String currency;
  final String location;
  final String? description;
  final String? imageUrl;
  final String? companyId;

  DiscoverProduct({
    required this.id,
    required this.name,
    required this.companyName,
    required this.category,
    required this.price,
    this.priceUnit = 'unit',
    this.currency = 'INR',
    required this.location,
    this.description,
    this.imageUrl,
    this.companyId,
  });

  factory DiscoverProduct.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;
      if (priceValue is double) return priceValue;
      if (priceValue is int) return priceValue.toDouble();
      if (priceValue is String) {
        return double.tryParse(priceValue) ?? 0.0;
      }
      return 0.0;
    }

    return DiscoverProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      companyName: json['companyName']?.toString() ?? 'Unknown Company',
      category: json['category']?.toString() ?? 'Uncategorized',
      price: parsePrice(json['price']),
      priceUnit: json['priceUnit']?.toString() ?? 'unit',
      currency: json['currency']?.toString() ?? 'INR',
      location: json['location']?.toString() ?? 'Location not specified',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      companyId: json['companyId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyName': companyName,
      'category': category,
      'price': price,
      'priceUnit': priceUnit,
      'currency': currency,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'companyId': companyId,
    };
  }

  String get formattedPrice {
    if (currency == 'INR') {
      return '₹${price.toStringAsFixed(2)}';
    }
    return '$currency ${price.toStringAsFixed(2)}';
  }
}
