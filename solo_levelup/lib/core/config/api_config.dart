class ApiConfig {
  // Backend API base URL
  static const String baseUrl =
      'https://productivity-app-ht2f.onrender.com/api';

  // API Endpoints
  static const String playerEndpoint = '/player';
  static const String questsEndpoint = '/quests';
  static const String templatesEndpoint = '/templates';
  static const String achievementsEndpoint = '/achievements';
  static const String analyticsEndpoint = '/analytics';
  static const String goalsEndpoint = '/goals';
  static const String timerEndpoint = '/timer';
  static const String cardioEndpoint = '/cardio';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
