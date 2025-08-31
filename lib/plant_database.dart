import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'plant.dart';

class PlantDatabase {
  static final PlantDatabase instance = PlantDatabase._init();
  static Database? _database;

  PlantDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plants.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imageUrl TEXT
      )
    ''');
  }

  Future<Plant> insertPlant(Plant plant) async {
    final db = await instance.database;
    final id = await db.insert('plants', plant.toMap());
    return plant.copyWith(id: id);
  }

  Future<List<Plant>> getPlants() async {
    final db = await instance.database;
    final result = await db.query('plants');
    return result.map((map) => Plant.fromMap(map)).toList();
  }

  Future<int> deletePlant(int id) async {
    final db = await instance.database;
    return await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

extension PlantCopyWith on Plant {
  Plant copyWith({int? id, String? name, String? imageUrl}) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
