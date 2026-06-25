/// API configuration for 智健 backend.
class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8000'; // Windows / iOS simulator
  // For iOS simulator, use: 'http://localhost:8000'
  // For real device, use your machine's local IP

  static const String apiPrefix = '/api';

  // Endpoints
  static const String health = '$apiPrefix/health';
  static const String personalities = '$apiPrefix/personalities';

  // Users
  static const String userRegister = '$apiPrefix/users/register';
  static String userProfile(String uid) => '$apiPrefix/users/$uid';
  static String userPersonality(String uid) => '$apiPrefix/users/$uid/personality';

  // Photos
  static const String photoUpload = '$apiPrefix/photos/upload';
  static String photosByDate(String uid, String date) =>
      '$apiPrefix/photos/$date?user_id=$uid';
  static String photosRange(String uid, String start, String end, String type) =>
      '$apiPrefix/photos/range?user_id=$uid&start_date=$start&end_date=$end&photo_type=$type';

  // Reports
  static String reportHistory(String uid) =>
      '$apiPrefix/reports/history?user_id=$uid';
  static String reportById(String rid) => '$apiPrefix/reports/$rid';
  static String reportSwitchPersonality(String rid) =>
      '$apiPrefix/reports/$rid/switch-personality';

  // Plans
  static String todayPlan(String uid) =>
      '$apiPrefix/plans/today?user_id=$uid';
  static String planHistory(String uid) =>
      '$apiPrefix/plans/history?user_id=$uid';
  static String planStatus(String pid) => '$apiPrefix/plans/$pid/status';
  static String exerciseResult(String eid) => '$apiPrefix/plans/exercises/$eid';
  static const String exerciseLibrary = '$apiPrefix/plans/exercises/library';

  // Calendar
  static String monthCalendar(String uid, int year, int month) =>
      '$apiPrefix/calendar/month?user_id=$uid&year=$year&month=$month';
  static String dayDetail(String uid, String date) =>
      '$apiPrefix/calendar/day/$date?user_id=$uid';
  static String yearHeatmap(String uid, int year) =>
      '$apiPrefix/calendar/heatmap?user_id=$uid&year=$year';
  static const String compare = '$apiPrefix/calendar/compare';
}
