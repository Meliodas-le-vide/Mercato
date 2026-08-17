class ApiConstants {
  static const String baseUrl = "http://192.168.100.64:5000/api";
  
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String refreshToken = "$baseUrl/auth/refreshToken";
  static const String players = "$baseUrl/players";
  static const String media = "$baseUrl/media";
  static const String logout = "$baseUrl/auth/logout";
}