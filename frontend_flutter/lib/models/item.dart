class Item {
  final String id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final String? localImagePath; // Optional for local display

  Item({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.localImagePath,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      description: map['description'],
      imageUrl: map['image_url'],
    );
  }
}
