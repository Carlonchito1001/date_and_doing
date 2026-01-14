import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _api = ApiService();
  final _sp = SharedPreferencesService();
  final _picker = ImagePicker();

  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String _fullName = '';
  String _ageText = '';
  String? _avatarUrl; // URL actual
  String? _avatarBase64; // NUEVA imagen base64

  String? _selectedCountry;
  String? _selectedCity;

  bool _loading = true;
  bool _saving = false;

  static const int _maxAboutChars = 300;

  final _countries = ["Perú", "México", "Argentina", "Chile"];
  final _cities = ["Iquitos", "Lima", "Cusco", "Arequipa"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _occupationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  // =================== LOAD USER ===================

  Future<void> _loadUserData() async {
    final userInfo = await _sp.getUserInfo();

    if (!mounted) return;

    if (userInfo != null) {
      setState(() {
        _fullName = userInfo['use_txt_fullname'] ?? 'Usuario';
        _ageText = userInfo['use_txt_age']?.toString() ?? '—';
        _avatarUrl = userInfo['use_txt_avatar'];

        _selectedCountry = userInfo['use_txt_country'];
        _selectedCity = userInfo['use_txt_city'];

        _occupationController.text = userInfo['use_txt_occupation'] ?? '';
        _aboutController.text = userInfo['use_txt_description'] ?? '';

        _loading = false;
      });
    } else {
      _loading = false;
    }
  }

  // =================== IMAGE PICK ===================

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 100);

    if (picked == null) return;

    final compressed = await _compressImage(File(picked.path));
    final bytes = await compressed.readAsBytes();

    setState(() {
      _avatarBase64 = base64Encode(bytes);
      _avatarUrl = null; // prioridad al base64
    });
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 600,
      minHeight: 600,
      format: CompressFormat.jpeg,
    );

    if (result == null) return file;

    // result може бути XFile (новий) або File (старий). Конвертуємо безпечно:
    final path = (result is XFile) ? result.path : (result as dynamic).path;
    return File(path);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galería"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Cámara"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =================== SAVE ===================

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {};

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    put('use_txt_country', _selectedCountry);
    put('use_txt_city', _selectedCity);
    put('use_txt_occupation', _occupationController.text);
    put('use_txt_description', _aboutController.text);

    // AVATAR
    if (_avatarBase64 != null) {
      payload['use_txt_avatar'] = 'data:image/jpeg;base64,$_avatarBase64';
    } else if (_avatarUrl != null) {
      payload['use_txt_avatar'] = _avatarUrl;
    }

    return payload;
  }

  Future<void> _saveProfile() async {
    final accessToken = await _sp.getAccessToken();
    final userId = await _sp.getUserId();

    if (accessToken == null || userId == null) {
      _toast("Sesión inválida");
      return;
    }

    final payload = _buildPayload();
    if (payload.isEmpty) {
      _toast("No hay cambios");
      return;
    }

    setState(() => _saving = true);

    try {
      await _api.editarPerfil(
        accessToken: accessToken,
        perfilData: payload,
        id: userId,
      );

      final refreshed = await _api.infoUser(accessToken: accessToken);
      await _sp.saveUserInfo(refreshed);

      if (!mounted) return;
      _toast("Perfil actualizado ✅");
      Navigator.pop(context, true);
    } catch (e) {
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final aboutLen = _aboutController.text.length;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePicker,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: cs.primaryContainer,
                backgroundImage: _avatarBase64 != null
                    ? MemoryImage(base64Decode(_avatarBase64!))
                    : (_avatarUrl != null
                          ? NetworkImage(_avatarUrl!) as ImageProvider
                          : null),
                child: _avatarBase64 == null && _avatarUrl == null
                    ? Icon(Icons.person, size: 48, color: cs.onPrimaryContainer)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showImagePicker,
              child: const Text("Cambiar foto"),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _occupationController,
              decoration: const InputDecoration(labelText: "Ocupación"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aboutController,
              maxLength: _maxAboutChars,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Sobre mí"),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text("$aboutLen / $_maxAboutChars"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text("Guardar cambios"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
