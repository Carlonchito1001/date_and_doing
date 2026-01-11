class ApiEndpoints {
  //Login
  static String baseUrl = 'https://services.fintbot.pe/api';
  static String login = '$baseUrl/auth/firebase/';
  static String infoUser = '$baseUrl/auth/me/';
  static String fcmToken = '$baseUrl/auth/users/';

  //home - match - likes

  static String sugerenciasMatch =
      '$baseUrl/dateanddo/discover/?radius_km=10&limit=1000000';
  static String swipes = '$baseUrl/dateanddo/swipes/';
  static String refreshToken = '$baseUrl/auth/token/refresh/';
  static String allMatches = '$baseUrl/dateanddo/matches/';
  static String allChats = '$baseUrl/dateanddo/messages/';
  static String editarPerfil = '$baseUrl/auth/users/';
  static String dates = '$baseUrl/dateanddo/dates/';
  static String dateById(int id) => "$baseUrl/dateanddo/dates/$id/";
  static String messages = "$baseUrl/dateanddo/messages/";
}
