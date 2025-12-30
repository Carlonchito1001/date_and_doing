import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/location/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/dd_user.dart';
import '../service/shared_preferences_service.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  // ================= INIT =================
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize();
    _isInitialized = true;
  }

  // ================= DEBUG TOKEN =================
  void _printFullToken(String token) {
    const int chunkSize = 500;
    for (int i = 0; i < token.length; i += chunkSize) {
      final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;
      print(
        '🔐 FIREBASE TOKEN PART ${i ~/ chunkSize + 1}: '
        '${token.substring(i, end)}',
      );
    }
  }

  String _cleanToken(String token) {
    return token.trim().replaceAll('\n', '').replaceAll('\r', '');
  }

  String _pickAccess(Map<String, dynamic> json) {
    final v = json['access_token'] ?? json['access'];
    if (v == null) {
      throw Exception('Login response sin access_token/access');
    }
    return v.toString();
  }

  // ================= LOGIN GOOGLE =================
  Future<DdUser> signInWithGoogle() async {
    await _ensureInitialized();

    // 1️⃣ Google Sign-In
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = await googleUser.authentication;

    // 2️⃣ Firebase credential (SOLO idToken)
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Usuario Firebase nulo');
    }

    // 3️⃣ Firebase ID Token (firetoken)
    final String? rawIdToken = await user.getIdToken(true);

    if (rawIdToken == null || rawIdToken.isEmpty) {
      throw Exception('Firebase ID Token es nulo');
    }

    // 🔥 AQUÍ SE IMPRIME EN PARTES (PARA PRUEBAS)
    _printFullToken(rawIdToken);

    // Token limpio para backend
    final String idToken = _cleanToken(rawIdToken);

    // 4️⃣ Login en tu backend
    final loginResponse = await ApiService().apiLoginFirebase(idToken);

    final sp = SharedPreferencesService();
    final String accessToken = _pickAccess(loginResponse);

    await sp.saveAccessToken(accessToken);

    // 5️⃣ Obtener info del usuario backend
    final userinfo = await ApiService().infoUser(accessToken: accessToken);
    await sp.saveUserInfo(userinfo);

    final int userId = (userinfo['use_int_id'] as num).toInt();

    // 6️⃣ FCM token (si existe)
    final prefs = await SharedPreferences.getInstance();
    final String? fcmToken = prefs.getString(SharedPreferencesService.fcmToken);

    // 7️⃣ Ubicación
    final gps = await LocationService().getCurrentPosition();
    final double latitude = double.parse(gps.latitude.toStringAsFixed(4));
    final double longitude = double.parse(gps.longitude.toStringAsFixed(4));

    // 8️⃣ Enviar FCM + ubicación
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await ApiService().apiFcm(
        fcmToken,
        userId,
        latitude,
        longitude,
        accessToken,
      );
    }

    // 9️⃣ Modelo local
    final ddUser = DdUser(
      id: user.uid,
      nombre: user.displayName ?? 'Usuario Google',
      email: user.email ?? '',
      provider: 'google',
      fotoUrl: user.photoURL ?? '',
      creadoEn: user.metadata.creationTime ?? DateTime.now(),
      esNuevo: userCredential.additionalUserInfo?.isNewUser ?? false,
    );

    // 🔟 Guardar sesión local
    await sp.saveUserSession(
      uid: ddUser.id,
      email: ddUser.email,
      phone: null,
      photoUrl: ddUser.fotoUrl,
      firebaseIdToken: idToken,
      accessToken: accessToken,
    );

    return ddUser;
  }

  // ================= LOGOUT =================
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _auth.signOut();
    await SharedPreferencesService().clearSession();
  }
}
