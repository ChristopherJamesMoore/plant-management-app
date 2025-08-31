import 'package:flutter/material.dart';
import 'plant_database.dart';
import 'plant.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class Reminder {
  final int? id;
  final String action;
  final String repeat;
  final String plantName;
  final DateTime date;

  Reminder({this.id, required this.action, required this.repeat, required this.plantName, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'repeat': repeat,
      'plantName': plantName,
      'date': date.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      action: map['action'] as String,
      repeat: map['repeat'] as String,
      plantName: map['plantName'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class ReminderDatabase {
  static final ReminderDatabase instance = ReminderDatabase._init();
  static Database? _database;

  ReminderDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);
    return await openDatabase(
      fullPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        repeat TEXT NOT NULL,
        plantName TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<Reminder> insertReminder(Reminder reminder) async {
    final db = await instance.database;
    final id = await db.insert('reminders', reminder.toMap());
    return reminder.copyWith(id: id);
  }

  Future<List<Reminder>> getReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders');
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

extension ReminderCopyWith on Reminder {
  Reminder copyWith({int? id, String? action, String? repeat, String? plantName, DateTime? date}) {
    return Reminder(
      id: id ?? this.id,
      action: action ?? this.action,
      repeat: repeat ?? this.repeat,
      plantName: plantName ?? this.plantName,
      date: date ?? this.date,
    );
  }
}

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final List<String> actions = ['Water', 'Re-potting', 'Pruning'];
  final List<String> repeats = ['Monthly', 'Daily', 'Weekly'];
  String? selectedAction;
  String? selectedRepeat;
  String? selectedPlant;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  List<Plant> plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final dbPlants = await PlantDatabase.instance.getPlants();
    setState(() {
      plants = dbPlants;
    });
  }

  Future<void> _saveReminder() async {
    if (selectedAction == null || selectedRepeat == null || selectedPlant == null || selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
      }
      return;
    }

    // Combine date and time if time is selected
    DateTime finalDate = selectedDate!;
    if (selectedTime != null) {
      finalDate = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
    }

    final reminder = Reminder(
      action: selectedAction!,
      repeat: selectedRepeat!,
      plantName: selectedPlant!,
      date: finalDate,
    );
    
    await ReminderDatabase.instance.insertReminder(reminder);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
    );
    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add reminder'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: actions.map((action) => ChoiceChip(
                label: Text(action),
                selected: selectedAction == action,
                onSelected: (selected) {
                  setState(() {
                    selectedAction = selected ? action : null;
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select plant',
                border: OutlineInputBorder(),
              ),
              value: selectedPlant,
              items: plants.map((plant) => DropdownMenuItem(
                value: plant.name,
                child: Text(plant.name),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPlant = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
                border: const OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: selectedDate == null 
                  ? '' 
                  : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Time (Optional)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
                border: const OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: selectedTime == null ? '' : selectedTime!.format(context),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Repeat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: repeats.map((repeat) => ChoiceChip(
                label: Text(repeat),
                selected: selectedRepeat == repeat,
                onSelected: (selected) {
                  setState(() {
                    selectedRepeat = selected ? repeat : null;
                  });
                },
              )).toList(),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveReminder,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// These classes can be removed if not used elsewhere
class ReminderActionButton extends StatelessWidget {
  final String label;
  const ReminderActionButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      child: Text(label),
    );
  }
}

class RepeatButton extends StatelessWidget {
  final String label;
  const RepeatButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      child: Text(label),
    );
  }
}