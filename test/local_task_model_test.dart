// UNIT TEST — no UI, no device needed. Tests pure logic: does LocalTask
// correctly convert itself to/from the Map that sqflite reads and writes?
// This is the same conversion task_db_service.dart relies on for every
// database read and write, so if this breaks, every screen using Task
// List would silently save or load corrupted data.

import 'package:flutter_test/flutter_test.dart';
import 'package:tecniforge_flutterapp/models/models.dart';

void main() {
  group('LocalTask', () {
    test('toMap() converts a task into the format sqflite expects', () {
      final task = LocalTask(
        id: 1,
        title: 'Confirm supplier invoice',
        completed: false,
        createdAt: DateTime(2026, 9, 13, 10, 30),
      );

      final map = task.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Confirm supplier invoice');
      expect(map['completed'], 0); // false must be stored as 0, not true/false
      expect(map['createdAt'], '2026-09-13T10:30:00.000');
    });

    test('toMap() stores completed = true as 1', () {
      final task = LocalTask(title: 'Done task', completed: true, createdAt: DateTime(2026, 1, 1));
      expect(task.toMap()['completed'], 1);
    });

    test('fromMap() rebuilds a task correctly from a database row', () {
      final row = {
        'id': 5,
        'title': 'Call client',
        'completed': 1,
        'createdAt': '2026-09-10T08:00:00.000',
      };

      final task = LocalTask.fromMap(row);

      expect(task.id, 5);
      expect(task.title, 'Call client');
      expect(task.completed, true); // 1 must become true, not stay as 1
      expect(task.createdAt, DateTime.parse('2026-09-10T08:00:00.000'));
    });

    test('toMap() then fromMap() returns an equivalent task (round trip)', () {
      final original = LocalTask(id: 9, title: 'Round trip test', completed: true, createdAt: DateTime(2026, 5, 5));
      final rebuilt = LocalTask.fromMap(original.toMap());

      expect(rebuilt.id, original.id);
      expect(rebuilt.title, original.title);
      expect(rebuilt.completed, original.completed);
      expect(rebuilt.createdAt, original.createdAt);
    });

    test('copyWith() changes only the completed flag, nothing else', () {
      final original = LocalTask(id: 2, title: 'Fixed title', completed: false, createdAt: DateTime(2026, 3, 3));
      final updated = original.copyWith(completed: true);

      expect(updated.completed, true);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.createdAt, original.createdAt);
    });
  });
}