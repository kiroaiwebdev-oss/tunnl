// lib/core/network/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────
  static const String login           = 'login.php';
  static const String logout          = 'logout.php';

  // ── App ───────────────────────────────────────────
  static const String appSettings     = 'app_settings.php';

  // ── Content ───────────────────────────────────────
  static const String banners         = 'banners.php';
  static const String sets            = 'sets.php';
  static const String questions       = 'questions.php';
  static const String tricks          = 'tricks.php';
  static const String shorts          = 'shorts.php';
  static const String dailyDose       = 'daily_dose.php';
  static const String dailyPractice   = 'daily_practice.php';
  static const String previousYear    = 'previous_year.php';
  static const String weeklyChallenge = 'weekly_challenge.php';

  // ── User ──────────────────────────────────────────
  static const String userProfile     = 'user_profile.php';
  static const String userXp          = 'user_xp.php';

  // ── Results ───────────────────────────────────────
  static const String submitResult    = 'submit_result.php';
  static const String submitDaily     = 'submit_daily_practice.php';
  static const String history         = 'history.php';

  // ── Leaderboard & Payments ────────────────────────
  static const String leaderboard     = 'leaderboard.php';
  static const String verifyPayment   = 'verify_payment.php';
}