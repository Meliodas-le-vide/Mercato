class ApiEndpoints {
  ApiEndpoints._(); // empêche l'instanciation

  static const String baseUrl = 'http://192.168.1.84:5000/api/v1';

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refreshToken';
  static const String forgotPassword = '$baseUrl/auth/forgotPassword';
  static const String verifyResetCode = '$baseUrl/auth/verifyResetCode';
  static const String resetPassword = '$baseUrl/auth/resetPassword';

  // ---------------------------------------------------------------------------
  // VIDEOS
  // ---------------------------------------------------------------------------
  static const String videoFeed = '$baseUrl/videos/feed';
  static const String videoUpload = '$baseUrl/videos/upload';
  static const String videoMyVideos = '$baseUrl/videos/my-videos';

  static String videoDetail(int id) => '$baseUrl/videos/$id';
  static String videoLike(int id) => '$baseUrl/videos/$id/like';
  static String videoViews(int id) => '$baseUrl/videos/$id/views';
  static String videoComments(int id) => '$baseUrl/videos/$id/comments';
  static String videoDelete(int id) => '$baseUrl/videos/$id';
  static String videoUpdate(int id) => '$baseUrl/videos/$id';
  static String videoByPlayer(int userId) => '$baseUrl/videos/player/$userId';

  // ---------------------------------------------------------------------------
  // PLAYERS
  // ---------------------------------------------------------------------------
  static const String playerMe = '$baseUrl/players/me';
  static const String playerAvatar = '$baseUrl/players/me/avatar';
  static const String playerStats = '$baseUrl/players/me/stats';
  static const String playerAnalytics = '$baseUrl/players/me/analytics';
  static const String playerSearch = '$baseUrl/players/search';

  static String playerById(int userId) => '$baseUrl/players/$userId';

  // ---------------------------------------------------------------------------
  // RECRUITER
  // ---------------------------------------------------------------------------
  static const String recruiterMe = '$baseUrl/recruiter/me';
  static const String recruiterUploadKyc = '$baseUrl/recruiter/upload-kyc';

  // ---------------------------------------------------------------------------
  // FAVORITES
  // ---------------------------------------------------------------------------
  static const String favorites = '$baseUrl/favorites';
  static String favoriteToggle(int playerId) => '$baseUrl/favorites/$playerId';

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------
  static const String notifications = '$baseUrl/notifications';
  static const String notificationsUnreadCount =
      '$baseUrl/notifications/unread-count';
  static const String notificationsReadAll = '$baseUrl/notifications/read-all';
  static String notificationRead(int id) => '$baseUrl/notifications/$id/read';

  // ---------------------------------------------------------------------------
  // MESSAGES
  // ---------------------------------------------------------------------------
  static const String conversations = '$baseUrl/messages/conversations';
  static const String messages = '$baseUrl/messages';

  static String conversationMessages(int userId) =>
      '$baseUrl/messages/conversations/$userId';
  static String markConversationRead(int userId) =>
      '$baseUrl/messages/conversations/$userId/read';

  // ---------------------------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------------------------
  static const String events = '$baseUrl/events';
  static const String myEvents = '$baseUrl/events/me';
  static String eventDetail(int id) => '$baseUrl/events/$id';

  // ---------------------------------------------------------------------------
  // REPORTS
  // ---------------------------------------------------------------------------
  static const String reports = '$baseUrl/reports';

  // ---------------------------------------------------------------------------
  // ADMIN
  // ---------------------------------------------------------------------------
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminUsersDelete = '$baseUrl/admin/users';
  static const String adminRecruiters = '$baseUrl/admin/recruiters';
  static const String adminReports = '$baseUrl/admin/reports';

  static String adminUserBan(int userId) => '$baseUrl/admin/users/$userId/ban';
  static String adminRecruiterVerify(int profileId) =>
      '$baseUrl/admin/recruiters/$profileId/verify';
  static String adminReportReview(int reportId) =>
      '$baseUrl/admin/reports/$reportId';
}
