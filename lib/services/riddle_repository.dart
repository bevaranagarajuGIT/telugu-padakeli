import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/riddle.dart';

abstract interface class RiddleRepository {
  Future<List<Riddle>> load();
}

class LocalRiddleRepository implements RiddleRepository {
  const LocalRiddleRepository();

  @override
  Future<List<Riddle>> load() async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/data/riddles.json'),
    );
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['riddles'] is! List) {
      throw const FormatException('Unsupported riddle collection.');
    }
    final riddles = <Riddle>[];
    final ids = <String>{};
    for (final entry in decoded['riddles'] as List) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid riddle entry.');
      }
      final riddle = Riddle.fromJson(entry);
      if (!ids.add(riddle.id)) {
        throw FormatException('Duplicate riddle: ${riddle.id}.');
      }
      riddles.add(riddle);
    }
    if (riddles.isEmpty) {
      throw const FormatException('The riddle collection is empty.');
    }
    return List.unmodifiable(riddles);
  }
}
