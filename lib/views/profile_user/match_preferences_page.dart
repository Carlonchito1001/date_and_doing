import 'package:flutter/material.dart';

class MatchPreferencesPage extends StatefulWidget {
  const MatchPreferencesPage({super.key});

  @override
  State<MatchPreferencesPage> createState() => _MatchPreferencesPageState();
}

class _MatchPreferencesPageState extends State<MatchPreferencesPage> {
  // Me gustaría conocer
  String _targetGender = "todos"; // "mujer" | "hombre" | "todos"

  // Rango de edad
  double _minAge = 18;
  double _maxAge = 35;

  // Qué estás buscando
  String _lookingFor = "relacion"; // "relacion" | "casual" | "amistad" | "noc"

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Preferencias")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======== Me gustaría conocer ========
              _SectionHeader(
                icon: Icons.people_alt_rounded,
                iconColor: cs.primary,
                title: "Me gustaría conocer",
              ),
              const SizedBox(height: 4),
              Text(
                "¿A quién te gustaría conocer en la app?",
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      label: "Mujer",
                      icon: Icons.woman_rounded,
                      isSelected: _targetGender == "mujer",
                      onTap: () => setState(() => _targetGender = "mujer"),
                      selectedBorderColor: cs.primary,
                      selectedBg: cs.primary.withOpacity(0.10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceCard(
                      label: "Hombre",
                      icon: Icons.man_rounded,
                      isSelected: _targetGender == "hombre",
                      onTap: () => setState(() => _targetGender = "hombre"),
                      selectedBorderColor: cs.primary,
                      selectedBg: cs.primary.withOpacity(0.10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceCard(
                      label: "Todos",
                      icon: Icons.group_rounded,
                      isSelected: _targetGender == "todos",
                      onTap: () => setState(() => _targetGender = "todos"),
                      selectedBorderColor: cs.secondary,
                      selectedBg: cs.secondary.withOpacity(0.10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ======== Rango de edad ========
              _SectionHeader(
                icon: Icons.cake_rounded,
                iconColor: Colors.teal,
                title: "Rango de edad",
              ),
              const SizedBox(height: 4),
              Text(
                "¿Qué rango de edad te interesa?",
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // linea top con edades grandes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              "Edad mínima",
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _minAge.toInt().toString(),
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 24,
                          height: 2,
                          color: cs.onSurface.withOpacity(0.2),
                        ),
                        Column(
                          children: [
                            Text(
                              "Edad máxima",
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _maxAge.toInt().toString(),
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Slider min
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Edad mínima: ${_minAge.toInt()} años",
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Slider(
                      min: 18,
                      max: 80,
                      value: _minAge,
                      onChanged: (v) {
                        setState(() {
                          _minAge = v.clamp(18, _maxAge);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Edad máxima: ${_maxAge.toInt()} años",
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Slider(
                      min: 18,
                      max: 80,
                      value: _maxAge,
                      onChanged: (v) {
                        setState(() {
                          _maxAge = v.clamp(_minAge, 80);
                        });
                      },
                      activeColor: Colors.black87,
                      inactiveColor: Colors.black12,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ======== Qué estás buscando ========
              _SectionHeader(
                icon: Icons.favorite_border_rounded,
                iconColor: Colors.green,
                title: "¿Qué estás buscando?",
              ),
              const SizedBox(height: 4),
              Text(
                "Ayúdanos a encontrar lo que buscas",
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ChoiceCard(
                    label: "Relación seria",
                    icon: Icons.favorite_rounded,
                    isSelected: _lookingFor == "relacion",
                    onTap: () => setState(() => _lookingFor = "relacion"),
                    selectedBorderColor: cs.primary,
                    selectedBg: cs.primary.withOpacity(0.10),
                    width:
                        (MediaQuery.of(context).size.width - 16 * 2 - 10) /
                        2, // 2 por fila
                  ),
                  _ChoiceCard(
                    label: "Algo casual",
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    isSelected: _lookingFor == "casual",
                    onTap: () => setState(() => _lookingFor = "casual"),
                    selectedBorderColor: Colors.orange,
                    selectedBg: Colors.orange.withOpacity(0.10),
                    width:
                        (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
                  ),
                  _ChoiceCard(
                    label: "Amistad",
                    icon: Icons.group_rounded,
                    isSelected: _lookingFor == "amistad",
                    onTap: () => setState(() => _lookingFor = "amistad"),
                    selectedBorderColor: cs.secondary,
                    selectedBg: cs.secondary.withOpacity(0.10),
                    width:
                        (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
                  ),
                  _ChoiceCard(
                    label: "Aún no lo sé",
                    icon: Icons.help_outline_rounded,
                    isSelected: _lookingFor == "noc",
                    onTap: () => setState(() => _lookingFor = "noc"),
                    selectedBorderColor: Colors.grey,
                    selectedBg: Colors.grey.withOpacity(0.10),
                    width:
                        (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ======== Tarjeta info ========
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "¿Por qué son importantes las preferencias?",
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tus preferencias nos ayudan a encontrar los mejores matches para ti. "
                            "Cuanto más específicas sean, más precisas serán nuestras recomendaciones.\n\n"
                            "✨ Puedes actualizar tus preferencias en cualquier momento para mejorar tu experiencia.",
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade800,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // TODO: guardar preferencias
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar preferencias"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== WIDGETS REUTILIZABLES ==================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBorderColor;
  final Color selectedBg;
  final double? width;

  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.selectedBorderColor,
    required this.selectedBg,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bgColor = isSelected ? selectedBg : cs.surface;
    final borderColor = isSelected
        ? selectedBorderColor
        : cs.outlineVariant.withOpacity(0.4);

    Widget content = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected
                ? selectedBorderColor
                : cs.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? selectedBorderColor
                  : cs.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: content,
    );
  }
}
