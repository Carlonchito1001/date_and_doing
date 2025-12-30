import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:date_and_doing/api/api_endpoints.dart';
import 'package:date_and_doing/service/shared_preferences_service.dart';

class ApiService {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  Completer<void>? _refreshCompleter;

  String _cleanToken(String token) {
    return token.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  String _pickAccess(Map<String, dynamic> json) {
    final v = json['access_token'] ?? json['access'];
    if (v == null) throw Exception('Respuesta sin access_token/access');
    return v.toString();
  }

  String? _pickRefresh(Map<String, dynamic> json) {
    final v = json['refresh_token'] ?? json['refresh'];
    return v?.toString();
  }

  Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function(String accessToken) request,
  ) async {
    final access = await _prefs.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No hay access_token guardado.');
    }

    http.Response res = await request(access);

    if (res.statusCode != 401) return res;

    final ok = await _ensureRefresh();
    if (!ok) throw Exception('Sesión expirada (refresh falló).');

    final newAccess = await _prefs.getAccessToken();
    if (newAccess == null || newAccess.isEmpty) {
      throw Exception('No se obtuvo nuevo access_token.');
    }

    return request(newAccess);
  }

  Future<bool> _ensureRefresh() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final a = await _prefs.getAccessToken();
      return a != null && a.isNotEmpty;
    }

    _refreshCompleter = Completer<void>();

    try {
      final refresh = await _prefs.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _prefs.clearSession();
        return false;
      }

      final data = await refreshToken(refreshToken: refresh);

      final newAccess = _pickAccess(data);
      final newRefresh = _pickRefresh(data);

      await _prefs.saveAccessToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _prefs.saveRefreshToken(newRefresh);
      }

      return true;
    } catch (_) {
      await _prefs.clearSession();
      return false;
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  // ================== LOGIN FIREBASE ==================
  Future<Map<String, dynamic>> apiLoginFirebase(String firebaseIdToken) async {
    final cleanToken = _cleanToken(firebaseIdToken);
    final url = ApiEndpoints.login;
    final payload = {'firebase_id_token': cleanToken};

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Service-Code': 'dateanddo',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // ✅ guardado automático tokens si vienen
      final access = _pickAccess(data);
      await _prefs.saveAccessToken(access);

      final refresh = _pickRefresh(data);
      if (refresh != null && refresh.isNotEmpty) {
        await _prefs.saveRefreshToken(refresh);
      }

      return data;
    }

    throw Exception(
      'Failed to login: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== FCM ==================
  Future<void> apiFcm(
    String fcmToken,
    int id,
    double latitude,
    double longitude,
    String accessToken, // no se usa, lo dejo para no romper tu firma
  ) async {
    final response = await _requestWithRefresh((token) {
      return http.patch(
        Uri.parse('${ApiEndpoints.fcmToken}$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Service-Code': 'dateanddo',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'use_txt_fcm': fcmToken,
          'use_double_latitude': latitude,
          'use_double_longitude': longitude,
        }),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(
      'Failed to register FCM token: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== INFO USER ==================
  Future<Map<String, dynamic>> infoUser({required String accessToken}) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.infoUser),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to get user info: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== SUGERENCIAS ==================
  Future<List<Map<String, dynamic>>> sugerenciasMatch({
    required String accessToken,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.sugerenciasMatch),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get suggestions: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== LIKES ==================
  Future<void> likes({
    required String accessToken,
    required int targetUserId,
    required String type,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.post(
        Uri.parse(ApiEndpoints.swipes),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'use_int_target': targetUserId,
          'ddw_txt_action': type,
        }),
      );
    });

    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(
      'Failed to like user: ${response.statusCode} - ${response.body}',
    );
  }

  // ================== REFRESH TOKEN ==================
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.refreshToken),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Service-Code': 'dateanddo',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to refresh token: ${response.statusCode} - ${response.body}',
    );
  }

  //==================Todos los Matches =====================//

  Future<List<Map<String, dynamic>>> allMatches({
    required String accessToken,
  }) async {
    final response = await _requestWithRefresh((token) {
      return http.get(
        Uri.parse(ApiEndpoints.allMatches),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to get all matches: ${response.statusCode} - ${response.body}',
    );
  }
}
