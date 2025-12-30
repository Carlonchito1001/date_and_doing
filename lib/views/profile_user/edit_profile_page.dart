import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _selectedCountry;
  String? _selectedCity;
  final TextEditingController _occupationController = TextEditingController(
    text: "Diseñador Gráfico",
  );
  final TextEditingController _aboutController = TextEditingController(
    text:
        "Me apasiona el arte urbano, el diseño creativo y conocer personas con intereses similares.",
  );

  static const int _maxAboutChars = 300;

  // Ejemplo de datos (puedes conectarlo luego a tu backend)
  final List<String> _countries = ["Perú", "México", "Argentina", "Chile"];
  final List<String> _cities = ["Iquitos", "Lima", "Cusco", "Arequipa"];

  @override
  void dispose() {
    _occupationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

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
              // Avatar
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
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: abrir bottom sheet para cambiar foto
                      },
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

              // Nombre (no editable)
              _buildLabelWithHint(
                context,
                label: "Nombre Completo",
                hint: "(No editable)",
              ),
              const SizedBox(height: 4),
              _buildReadOnlyField(
                context,
                icon: Icons.person_outline,
                value: "Juan Pérez",
              ),
              const SizedBox(height: 16),

              // Edad (no editable)
              _buildLabelWithHint(
                context,
                label: "Edad",
                hint: "(No editable)",
              ),
              const SizedBox(height: 4),
              _buildReadOnlyField(
                context,
                icon: Icons.cake_outlined,
                value: "28 años",
              ),

              const SizedBox(height: 24),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 12),

              // Título "Información editable"
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

              // País
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
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Ciudad
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
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Ocupación
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

              // Algo sobre mí
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

              // Card Datos protegidos
              _buildSecurityCard(context),

              const SizedBox(height: 24),

              // Botón Guardar cambios
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // TODO: enviar datos al backend
                  },
                  child: const Text("Guardar cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Widgets auxiliares ----------

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
