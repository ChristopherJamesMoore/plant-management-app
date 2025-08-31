class Plant {
  final int? id;
  final String name;
  final String imageUrl;

  Plant({this.id, required this.name, required this.imageUrl});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int?,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String,
    );
  }
}
