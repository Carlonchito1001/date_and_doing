import 'package:flutter/material.dart';

class DdCreateActivityPage extends StatefulWidget {
  const DdCreateActivityPage({super.key});

  @override
  State<DdCreateActivityPage> createState() => _DdCreateActivityPageState();
}

class _DdCreateActivityPageState extends State<DdCreateActivityPage> {
  // Simulación: con quién estás creando la cita
  final String partnerName = "Ana García";

  // Estado UI
  bool _isSaving = false;
  String _selectedId = "playa";

  // Fecha (manual)
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  final List<_ActivityItem> _activities = const [
    _ActivityItem(id: "playa", emoji: "🏖️", label: "Día de Playa"),
    _ActivityItem(id: "parque", emoji: "🌳", label: "Salida al Parque"),
    _ActivityItem(id: "cena", emoji: "🍽️", label: "Cena Romántica"),
    _ActivityItem(id: "cafe", emoji: "☕", label: "Café"),
    _ActivityItem(id: "cine", emoji: "🎬", label: "Cine"),
    _ActivityItem(id: "museo", emoji: "🏛️", label: "Museo"),
    _ActivityItem(id: "concierto", emoji: "🎵", label: "Concierto"),
    _ActivityItem(id: "senderismo", emoji: "🥾", label: "Senderismo"),
    _ActivityItem(id: "picnic", emoji: "🧺", label: "Picnic"),
    _ActivityItem(id: "otra", emoji: "✨", label: "Otra..."),
  ];

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  // ===== Helpers =====

  _ActivityItem get _selectedActivity =>
      _activities.firstWhere((a) => a.id == _selectedId);

  DateTime? _tryParseDate() {
    final dd = int.tryParse(_dayCtrl.text.trim());
    final mm = int.tryParse(_monthCtrl.text.trim());
    final yyyy = int.tryParse(_yearCtrl.text.trim());

    if (dd == null || mm == null || yyyy == null) return null;
    if (yyyy < 1900 || yyyy > 2100) return null;

    try {
      final dt = DateTime(yyyy, mm, dd);
      // DateTime corrige automáticamente fechas inválidas (ej: 32/01) => hay que validar
      if (dt.year != yyyy || dt.month != mm || dt.day != dd) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFB53CF5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dayCtrl.text = picked.day.toString().padLeft(2, "0");
      _monthCtrl.text = picked.month.toString().padLeft(2, "0");
      _yearCtrl.text = picked.year.toString();
      setState(() {});
    }
  }

  // ===== Simulación de "crear cita" =====

  Future<void> _createDateSimulated() async {
    if (_isSaving) return;

    final dt = _tryParseDate();
    if (dt == null) {
      _toast(
        "Ingresa una fecha válida (DD/MM/AAAA) o selecciona desde el calendario.",
      );
      return;
    }

    setState(() => _isSaving = true);

    // Simula request al backend
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isSaving = false);

    final created = _DateCreated(
      id: "DD-${DateTime.now().millisecondsSinceEpoch}",
      partnerName: partnerName,
      activityLabel: _selectedActivity.label,
      activityId: _selectedActivity.id,
      date: dt,
      createdAt: DateTime.now(),
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _SuccessDialog(created: created),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top bar (degradado)
          Container(
            padding: EdgeInsets.only(top: top),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFF4FB8), Color(0xFFB53CF5)],
              ),
            ),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _TopIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Crear Actividad",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Planea una cita con $partnerName",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TopIconButton(
                    icon: Icons.phone,
                    onTap: () {
                      _toast("📞 Llamando (simulado) a $partnerName...");
                    },
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequiredLabel(text: "Tipo de Actividad"),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                    itemBuilder: (context, i) {
                      final item = _activities[i];
                      final selected = item.id == _selectedId;

                      return _ActivityCard(
                        emoji: item.emoji,
                        label: item.label,
                        selected: selected,
                        onTap: () => setState(() => _selectedId = item.id),
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  _RequiredLabel(text: "Fecha"),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      InkWell(
                        onTap: _openCalendar,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB53CF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: _DateField(
                          controller: _dayCtrl,
                          hint: "DD",
                          label: "Día",
                          maxLen: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "/",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black45,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: _DateField(
                          controller: _monthCtrl,
                          hint: "MM",
                          label: "Mes",
                          maxLen: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "/",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black45,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: _DateField(
                          controller: _yearCtrl,
                          hint: "AAAA",
                          label: "Año",
                          maxLen: 4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: _openCalendar,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E6F0)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.event, size: 18, color: Colors.black54),
                          SizedBox(width: 10),
                          Text(
                            "O selecciona desde el calendario",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Resumen simulado (como preview)
                  _PreviewCard(
                    partnerName: partnerName,
                    activity: _selectedActivity.label,
                    dateText: _prettyDateOrEmpty(),
                  ),

                  const SizedBox(height: 14),

                  // Botón crear cita (simulado)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _createDateSimulated,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4FB8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Crear cita",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyDateOrEmpty() {
    final dt = _tryParseDate();
    if (dt == null) return "—";
    final dd = dt.day.toString().padLeft(2, "0");
    final mm = dt.month.toString().padLeft(2, "0");
    final yyyy = dt.year.toString();
    return "$dd/$mm/$yyyy";
  }
}

// ================= UI Components =================

class _RequiredLabel extends StatelessWidget {
  final String text;
  const _RequiredLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: " *",
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFFF4FB8) : const Color(0xFFE8E8F2);
    final bg = selected ? const Color(0xFFFFEFF8) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 1.6 : 1.2),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Este _DateField está hecho para NO overflow (sin Column interno)
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final int maxLen;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.maxLen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        decoration: InputDecoration(
          counterText: "",
          labelText: label,
          hintText: hint,
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E6F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E6F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB53CF5)),
          ),
        ),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String partnerName;
  final String activity;
  final String dateText;

  const _PreviewCard({
    required this.partnerName,
    required this.activity,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vista previa",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _previewRow("Con:", partnerName),
          const SizedBox(height: 6),
          _previewRow("Actividad:", activity),
          const SizedBox(height: 6),
          _previewRow("Fecha:", dateText),
        ],
      ),
    );
  }

  static Widget _previewRow(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            k,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

// ================= Simulated Result Models =================

class _ActivityItem {
  final String id;
  final String emoji;
  final String label;

  const _ActivityItem({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

class _DateCreated {
  final String id;
  final String partnerName;
  final String activityLabel;
  final String activityId;
  final DateTime date;
  final DateTime createdAt;

  _DateCreated({
    required this.id,
    required this.partnerName,
    required this.activityLabel,
    required this.activityId,
    required this.date,
    required this.createdAt,
  });
}

class _SuccessDialog extends StatelessWidget {
  final _DateCreated created;
  const _SuccessDialog({required this.created});

  @override
  Widget build(BuildContext context) {
    final dd = created.date.day.toString().padLeft(2, "0");
    final mm = created.date.month.toString().padLeft(2, "0");
    final yyyy = created.date.year.toString();
    final dateText = "$dd/$mm/$yyyy";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFF8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFFFF4FB8),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "¡Cita creada!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Se creó la actividad con ${created.partnerName}.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            _infoRow("Actividad", created.activityLabel),
            const SizedBox(height: 8),
            _infoRow("Fecha", dateText),
            const SizedBox(height: 8),
            _infoRow("ID", created.id),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB53CF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Listo",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            k,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
