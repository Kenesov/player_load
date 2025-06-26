class ApiConfig {
  static const String baseUrl = 'https://sportrpe.diyarbek.uz';
  static const String apiVersion = '/api';

  // Authentication endpoints
  static const String login = '$apiVersion/users/login/';
  static const String register = '$apiVersion/users/users/';
  static const String me = '$apiVersion/users/me/';
  static const String tokenRefresh = '$apiVersion/users/token/refresh/';
  static const String testAuth = '$apiVersion/users/test-auth/';

  // Athletes endpoints
  static const String athletes = '$apiVersion/athletes/athletes/';
  static const String myProfile = '$apiVersion/users/me';

  // Coaches endpoints
  static const String coaches = '$apiVersion/users/coaches/';
  static const String myAthletes = '$apiVersion/users/coaches/my_athletes/';

  // Training Sessions endpoints
  static const String trainingSessions = '$apiVersion/trainings/training-sessions/';

  // RPE Records endpoints
  static const String rpeRecords = '$apiVersion/trainings/rpe-records/';
  static const String rpeScales = '$apiVersion/trainings/rpe-scales/';
  static const String rpeRecommendation = '$apiVersion/trainings/rpe-records/get_recommendation/';

  // Reports endpoints
  static const String athleteReport = '$apiVersion/trainings/athlete-report/';
  static const String teamReport = '$apiVersion/trainings/team-report/';

  // Recommendation levels
  static const String recommendationLevels = '$apiVersion/trainings/recommendation-levels/';
}
