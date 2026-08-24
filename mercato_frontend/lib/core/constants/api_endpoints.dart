class ApiEndpoints {
 
  static const String baseUrl = 'http://192.168.1.78:5000/api';


  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refreshToken';
  static const String forgotPassword = '$baseUrl/auth/forgotPassword';



  static const String videoFeed = '$baseUrl/v1/videos/feed';
  static const String videoUpload = '$baseUrl/v1/videos/upload';
  static String videoDetail(int id) => '$baseUrl/v1/videos/$id';
  static String videoLike(int id) => '$baseUrl/v1/videos/$id/like';
  static String videoViews(int id) => '$baseUrl/v1/videos/$id/views';
  static String videoComments(int id) => '$baseUrl/v1/videos/$id/comments';
  static String videoDelete(int id) => '$baseUrl/v1/videos/$id';
  static String videoUpdate(int id) => '$baseUrl/v1/videos/$id';
 

  static const String playerMe = '$baseUrl/v1/players/me';
  static const String playerAvatar = '$baseUrl/v1/players/me/avatar';
  static const String videoMyVideos = '$baseUrl/v1/videos/my-videos';
  static const String playerStats = '$baseUrl/v1/players/me/stats';
  static const String playerAnalytics = '$baseUrl/v1/players/me/analytics';


}