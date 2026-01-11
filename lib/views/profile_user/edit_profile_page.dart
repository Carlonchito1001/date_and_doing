// lib/views/profile_user/edit_profile_page.dart
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _selectedCountry;
  String? _selectedCity;

  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String _fullName = '';
  String _ageText = '';
  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;

  static const int _maxAboutChars = 300;

  final List<String> _countries = ["Perú", "México", "Argentina", "Chile"];
  final List<String> _cities = ["Iquitos", "Lima", "Cusco", "Arequipa"];

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

  Future<void> _loadUserData() async {
    final sp = SharedPreferencesService();
    final userInfo = await sp.getUserInfo();

    if (!mounted) return;

    if (userInfo != null) {
      final fullname = (userInfo['use_txt_fullname'] ?? '').toString();
      final age = userInfo['use_txt_age'];
      final country = userInfo['use_txt_country'];
      final city = userInfo['use_txt_city'];
      final occupation = userInfo['use_txt_occupation'];
      final desc = userInfo['use_txt_description'];
      final avatar = userInfo['use_txt_avatar'];

      setState(() {
        _fullName = fullname.isEmpty ? 'Usuario' : fullname;
        _ageText = (age == null || age.toString().trim().isEmpty)
            ? '—'
            : age.toString();

        _selectedCountry =
            (country == null || country.toString().trim().isEmpty)
            ? null
            : country.toString();
        _selectedCity = (city == null || city.toString().trim().isEmpty)
            ? null
            : city.toString();

        _occupationController.text = (occupation ?? '').toString();
        _aboutController.text = (desc ?? '').toString();

        _avatarUrl = (avatar == null || avatar.toString().trim().isEmpty)
            ? null
            : avatar.toString();

        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {};

    void putIfValid(String key, dynamic value) {
      if (value == null) return;
      if (value is String) {
        final v = value.trim();
        if (v.isEmpty) return;
        payload[key] = v;
        return;
      }
      payload[key] = value;
    }

    putIfValid('use_txt_country', _selectedCountry);
    putIfValid('use_txt_city', _selectedCity);
    putIfValid('use_txt_occupation', _occupationController.text);
    putIfValid('use_txt_description', _aboutController.text);

    return payload;
  }

  Future<void> _saveProfile() async {
    final sp = SharedPreferencesService();

    final accessToken = await sp.getAccessToken();
    final userInfo = await sp.getUserInfo();

    if (accessToken == null || accessToken.isEmpty) {
      _toast('No hay access token. Vuelve a iniciar sesión.');
      return;
    }
    if (userInfo == null) {
      _toast('No hay userInfo guardado.');
      return;
    }

    final idRaw = userInfo['use_int_id'];
    if (idRaw == null) {
      _toast('userInfo no trae use_int_id.');
      return;
    }
    final int userId = (idRaw as num).toInt();

    final payload = _buildPayload();
    if (payload.isEmpty) {
      _toast('No hay cambios para guardar.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService().editarPerfil(
        accessToken: accessToken,
        perfilData: payload,
        id: userId,
      );

      final refreshed = await ApiService().infoUser(accessToken: accessToken);
      await sp.saveUserInfo(refreshed);

      if (!mounted) return;
      setState(() {
        _saving = false;
      });

      _toast('Perfil actualizado ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Error: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Editar perfil"),
          backgroundColor: cs.surface,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final aboutLength = _aboutController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar perfil"),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: cs.surface,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: cs.onSurface.withOpacity(0.7),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.camera_alt_outlined, color: cs.primary),
                      label: Text(
                        "Cambiar foto",
                        style: textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabelWithHint(
                context,
                label: "Nombre Completo",
                hint: "(No editable)",
              ),
              const SizedBox(height: 4),
              _buildReadOnlyField(
                context,
                icon: Icons.person_outline,
                value: _fullName,
              ),
              const SizedBox(height: 16),
              _buildLabelWithHint(
                context,
                label: "Edad",
                hint: "(No editable)",
              ),
              const SizedBox(height: 4),
              _buildReadOnlyField(
                context,
                icon: Icons.cake_outlined,
                value: _ageText == '—' ? '—' : '$_ageText años',
              ),
              const SizedBox(height: 24),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Información editable",
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "País",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              _buildDropdownField(
                context,
                value: _selectedCountry,
                hint: "Selecciona un país",
                items: _countries,
                onChanged: (value) => setState(() => _selectedCountry = value),
              ),
              const SizedBox(height: 16),
              Text(
                "Ciudad",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              _buildDropdownField(
                context,
                value: _selectedCity,
                hint: "Selecciona una ciudad",
                items: _cities,
                onChanged: (value) => setState(() => _selectedCity = value),
              ),
              const SizedBox(height: 16),
              Text(
                "Ocupación",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _occupationController,
                decoration: _inputDecoration(context).copyWith(
                  prefixIcon: const Icon(Icons.work_outline),
                  hintText: "Tu ocupación",
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Algo sobre mí",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _aboutController,
                maxLines: 5,
                maxLength: _maxAboutChars,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  context,
                ).copyWith(alignLabelWithHint: true, counterText: ""),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Máximo $_maxAboutChars caracteres",
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "$aboutLength/$_maxAboutChars",
                    style: textTheme.bodySmall?.copyWith(
                      color: aboutLength > _maxAboutChars
                          ? cs.error
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSecurityCard(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Guardar cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelWithHint(
    BuildContext context, {
    required String label,
    required String hint,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TextField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
        hintText: value,
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.7),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(context),
      icon: const Icon(Icons.arrow_drop_down),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Datos protegidos por seguridad",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tu nombre y edad no pueden ser modificados para garantizar la autenticidad y seguridad de todos los usuarios de la plataforma.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Si necesitas modificar estos datos, por favor contacta a nuestro equipo de soporte.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
