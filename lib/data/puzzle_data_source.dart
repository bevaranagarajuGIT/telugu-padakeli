import 'package:flutter/services.dart';

abstract class PuzzleDataSource {
  Future<String> loadPuzzlesJson();
}

class AssetPuzzleDataSource implements PuzzleDataSource {
  const AssetPuzzleDataSource({
    this.assetPath = 'assets/data/sample_puzzles.json',
  });

  final String assetPath;

  @override
  Future<String> loadPuzzlesJson() {
    return rootBundle.loadString(assetPath);
  }
}
