abstract class AuthService {
  Future<bool> get isSignedIn;
}

abstract class DailyPuzzleService {
  Future<int?> getTodayPuzzleId();
}

abstract class LeaderboardService {
  Future<void> submitScore({required String userId, required int score});
}

abstract class RewardsService {
  Future<void> addCoins({required String userId, required int coins});
}
