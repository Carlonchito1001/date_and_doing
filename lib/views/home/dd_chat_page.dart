import 'dart:convert';
import 'package:date_and_doing/views/history/history_levels.dart';
import 'package:date_and_doing/widgets/modal_day_chat.dart';
import 'package:date_and_doing/widgets/modal_alini_unlocked.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dd_mock_data.dart';

/// Modelo simple para el resultado del análisis IA
class AnalysisResult {
  final String partnerName;
  final String overallTitle; // Ej: "Evaluación General"
  final String toneLabel; // Ej: "Positivo"
  final String overallSummary; // Párrafo principal
  final Map<String, double> scores; // "Amabilidad" -> 85.0
  final List<String> positives;
  final String note;

  AnalysisResult({
    required this.partnerName,
    required this.overallTitle,
    required this.toneLabel,
    required this.overallSummary,
    required this.scores,
    required this.positives,
    required this.note,
  });
}

// 👇 días de chat global (luego esto vendrá de tu backend)
int ChatDay = 4;

class DdChatPage extends StatefulWidget {
  final String nombre; // contacto
  final String foto;

  const DdChatPage({super.key, required this.nombre, required this.foto});

  @override
  State<DdChatPage> createState() => _DdChatPageState();
}

class _DdChatPageState extends State<DdChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();

  /// Usuario logueado (simulado). Luego vendrá del login real.
  final String currentUser = "Juan";

  /// Historial de mensajes de este chat
  final List<Map<String, dynamic>> _messages = [];

  /// Estado IA
  bool _analyzing = false;

  // 👇 Para que el modal de desbloqueo de Alini solo salga una vez por sesión
  bool _shownAliniUnlockedThisSession = false;

  static const String _iaUrl =
      'https://n8n.fintbot.pe/webhook/be664844-a373-4376-888a-170049d6f2d5';

  static const String _defaultIaNote =
      "Este análisis es generado por IA y está basado en patrones de "
      "comunicación. Usa tu propio criterio para tomar decisiones sobre tus "
      "conexiones.";

  @override
  void initState() {
    super.initState();

    // cargamos historial mock según el nombre (Camila, Daniel, etc.)
    final historyMap = buildMockChatHistory();
    final initialMessages = historyMap[widget.nombre] ?? [];
    _messages.addAll(initialMessages);

    // Al abrir el chat, si ya cumplió los días, mostrar modal de desbloqueo Alini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAliniUnlocked();
    });
  }

  // ================== LÓGICA ALINI VIDEO CALL ==================

  void _checkAndShowAliniUnlocked() async {
    // Si NO ha cumplido 3 días -> no mostrar nada
    if (ChatDay < 3) return;

    // Si ya lo mostramos en esta sesión -> no repetir
    if (_shownAliniUnlockedThisSession) return;

    _shownAliniUnlockedThisSession = true;

    final wantsTry = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ModalAliniUnlocked(partnerName: widget.nombre),
    );

    // Si pulsa "Probar Alini"
    if (wantsTry == true) {
      _iniciarAliniVideoCall();
    }
  }

  void _iniciarAliniVideoCall() {
    // TODO: aquí va tu lógica real de videollamada Alini
    // Ejemplo por ahora:
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Iniciando Alini Video Call...")),
    );
  }

  void validateAliniDias({
    required BuildContext context,
    required int chatDay,
    required VoidCallback onAllowed,
  }) {
    // Bloquea si tiene 2 días o menos
    if (chatDay <= 2) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ModalDayChat(chatDay: chatDay),
      );
    } else {
      onAllowed(); // aquí haces la video call
    }
  }

  // ================== CHAT BÁSICO ==================

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final horaStr = TimeOfDay.fromDateTime(now).format(context); // ej. 8:23 PM
    final fechaStr = now.toIso8601String().substring(0, 10);

    setState(() {
      _messages.add({
        "autor": currentUser,
        "text": text,
        "hora": horaStr,
        "fecha": fechaStr,
      });
      _messageCtrl.clear();
    });
  }

  bool _esMio(Map<String, dynamic> msg) {
    return msg["autor"] == currentUser;
  }

  // ================== IA: FORMATEO & PARSERS ==================

  /// Convierte la conversación al formato:
  /// [hora] Autor:
  /// Mensaje
  String _buildConversationText(List<Map<String, dynamic>> msgs) {
    final buffer = StringBuffer();

    for (final m in msgs) {
      final String hora = (m["hora"] ?? "") as String;
      final String autor = (m["autor"] ?? "") as String;
      final String text = (m["text"] ?? "") as String;

      buffer.writeln("[$hora] $autor:");
      buffer.writeln(text);
      buffer.writeln(); // línea en blanco
    }

    return buffer.toString();
  }

  /// Intenta sacar texto "bonito" del body devuelto por n8n (para fallback)
  String _extractAnalysis(String body) {
    try {
      dynamic decoded = jsonDecode(body);

      // A veces n8n devuelve un string JSON dentro de otro string
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is Map<String, dynamic>) {
        final map = decoded;
        String? txt =
            map["analysis"] ??
            map["output"] ??
            map["resumen"] ??
            map["message"];
        if (txt is String) {
          return txt.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
        }
      }

      return body.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
    } catch (_) {
      return body.replaceAll(r'\n', '\n').replaceAll(r'\t', '  ');
    }
  }

  double _normalizePercent(dynamic raw) {
    double v;
    if (raw is num) {
      v = raw.toDouble();
    } else {
      v = double.tryParse(raw.toString()) ?? 0.0;
    }
    if (v <= 1.0) v *= 100.0; // 0.85 -> 85
    if (v < 0) v = 0;
    if (v > 100) v = 100;
    return v;
  }

  /// Parser especial para tu formato:
  /// {"output": "1. ... (85%)\n2. ... (90%) ..."}
  AnalysisResult _parseFromSingleOutput(String output, String partnerName) {
    final lines = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final Map<String, double> scores = {};
    final List<String> positives = [];
    double? probAvance; // para decidir "Positivo / Neutral / Riesgo"
    String overallSummary = "";

    final RegExp percentRegex = RegExp(r'(\d+)\s*%');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // quitamos "1. ", "2. ", etc.
      line = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');

      // separamos label y texto
      String label = "";
      String rest = line;
      final parts = line.split(':');
      if (parts.length >= 2) {
        label = parts[0].trim();
        rest = parts.sublist(1).join(':').trim();
      }

      // buscamos porcentaje
      double? pct;
      final match = percentRegex.firstMatch(rest);
      if (match != null) {
        pct = double.tryParse(match.group(1)!);
      }
      if (pct != null) {
        final key = label.isEmpty ? 'Indicador ${i + 1}' : label;
        scores[key] = _normalizePercent(pct);

        // si es la línea de Probabilidad de avance, la guardamos
        if (label.toLowerCase().contains("probabilidad de avance")) {
          probAvance = _normalizePercent(pct);
        }
      }

      // texto sin el "(85%)"
      final cleanRest = rest
          .replaceAll(percentRegex, '')
          .replaceAll('()', '')
          .trim();

      // usamos todas como bullets
      if (cleanRest.isNotEmpty) {
        positives.add(cleanRest);
      }

      // primera línea la usamos como resumen general
      if (i == 0) {
        overallSummary = cleanRest;
      }
    }

    // determinamos el tono global
    String toneLabel;
    final p = probAvance ?? 70; // si no viene, asumimos algo decente
    if (p >= 80) {
      toneLabel = "Muy positivo";
    } else if (p >= 60) {
      toneLabel = "Positivo";
    } else if (p >= 40) {
      toneLabel = "Neutral / con matices";
    } else {
      toneLabel = "Bajo / Riesgo";
    }

    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Evaluación de conversación",
      toneLabel: toneLabel,
      overallSummary: overallSummary,
      scores: scores,
      positives: positives,
      note: _defaultIaNote,
    );
  }

  /// Intenta parsear JSON estructurado; si solo hay "output", usamos el parser anterior
  AnalysisResult? _parseAnalysisResult(String body, String partnerName) {
    try {
      dynamic decoded = jsonDecode(body);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is! Map<String, dynamic>) return null;
      final map = decoded as Map<String, dynamic>;

      // 👉 si solo viene "output" como en tu ejemplo, lo parseamos a lo Fint
      if (map.length == 1 && map.containsKey("output")) {
        final String output = map["output"]?.toString() ?? "";
        if (output.isEmpty) return null;
        return _parseFromSingleOutput(output, partnerName);
      }

      // si algún día tienes un JSON más estructurado (overall_title, scores, etc.)
      final overallTitle = (map["overall_title"] ?? "Evaluación General")
          .toString();
      final toneLabel = (map["overall_label"] ?? map["tone"] ?? "Análisis")
          .toString();
      final overallSummary = (map["overall_summary"] ?? map["summary"] ?? "")
          .toString();

      final dynamic scoresRaw = map["scores"] ?? map["indicadores"];
      final Map<String, double> scores = {};
      if (scoresRaw is Map) {
        scoresRaw.forEach((key, value) {
          if (value != null) {
            scores[key.toString()] = _normalizePercent(value);
          }
        });
      }

      final dynamic posRaw =
          map["positives"] ?? map["aspects_positive"] ?? map["positivos"];
      final List<String> positives = [];
      if (posRaw is List) {
        positives.addAll(posRaw.map((e) => e.toString()));
      }

      final note = (map["note"] ?? _defaultIaNote).toString();

      return AnalysisResult(
        partnerName: partnerName,
        overallTitle: overallTitle,
        toneLabel: toneLabel,
        overallSummary: overallSummary,
        scores: scores,
        positives: positives,
        note: note,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fallback si no viene nada que podamos parsear
  AnalysisResult _fallbackAnalysis(String body, String partnerName) {
    final txt = _extractAnalysis(body);
    return AnalysisResult(
      partnerName: partnerName,
      overallTitle: "Análisis general",
      toneLabel: "Resumen IA",
      overallSummary: txt,
      scores: const {},
      positives: const [],
      note: _defaultIaNote,
    );
  }

  // ================== IA: UI Y LLAMADA ==================

  void _openAssistantOptions() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: cs.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Text(
                  "Análisis Fint IA",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Analiza la conversación con ${widget.nombre} para ver nivel de "
                  "interés, claridad y compatibilidad.",
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Icon(Icons.today, color: cs.primary),
                  title: Text(
                    "Analizar chat de hoy",
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Resumen emocional del día actual.",
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _analyzeChatForDay(DateTime.now(), mode: "today");
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_month_rounded,
                    color: cs.secondary,
                  ),
                  title: Text(
                    "Analizar un día específico",
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Elige una fecha concreta del historial.",
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      _analyzeChatForDay(picked, mode: "by_day");
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _analyzeChatForDay(DateTime day, {required String mode}) async {
    if (_messages.isEmpty) return;

    setState(() {
      _analyzing = true;
    });

    final String dayStr = day.toIso8601String().substring(0, 10);

    final filteredMessages = _messages
        .where((m) => m["fecha"] == dayStr)
        .toList();

    final messagesToSend = filteredMessages.isNotEmpty
        ? filteredMessages
        : _messages;

    final conversationText = _buildConversationText(messagesToSend);

    final payload = {
      "mode": mode, // "today" | "by_day"
      "date": dayStr,
      "partner_name": widget.nombre,
      "current_user": currentUser,
      "conversation_text": conversationText,
      "messages_raw": messagesToSend
          .map(
            (m) => {
              "author": m["autor"],
              "text": m["text"],
              "time": m["hora"],
              "date": m["fecha"],
            },
          )
          .toList(),
    };

    try {
      final uri = Uri.parse(_iaUrl);
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Intentamos parsear en modo "output" + porcentajes
        final result =
            _parseAnalysisResult(resp.body, widget.nombre) ??
            _fallbackAnalysis(resp.body, widget.nombre);

        _showAnalysisModal(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error ${resp.statusCode}: ${resp.reasonPhrase ?? 'al analizar el chat'}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con la IA: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  void _showAnalysisModal(AnalysisResult result) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: cs.primaryContainer.withOpacity(
                                0.95,
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: cs.onPrimaryContainer,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Análisis Fint IA",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Análisis de conversación con ${result.partnerName}",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Evaluación general (card verde)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Evaluación General",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                result.toneLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                result.overallSummary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Análisis de personalidad (barras)
                        if (result.scores.isNotEmpty) ...[
                          Text(
                            "Análisis de Personalidad",
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...result.scores.entries.map(
                            (e) => _buildScoreRow(
                              label: e.key,
                              value: e.value,
                              cs: cs,
                              textTheme: textTheme,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Aspectos positivos
                        if (result.positives.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade500,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Aspectos Positivos",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...result.positives.map(
                            (p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green.shade500,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Nota IA
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.15),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Nota: ",
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                TextSpan(
                                  text: result.note,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Botón "Entendido"
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Entendido"),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreRow({
    required String label,
    required double value,
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    final percentText = "${value.toStringAsFixed(0)}%";
    final progressValue = value / 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              Text(
                percentText,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: cs.surfaceVariant.withOpacity(0.7),
              valueColor: AlwaysStoppedAnimation<Color>(
                cs.primary.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== CICLO DE VIDA ==================

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  // ================== UI DEL CHAT ==================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.foto)),
            const SizedBox(width: 8),
            Text(widget.nombre),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryLevelsPage()),
              );
            },
          ),
          IconButton(
            tooltip: "Asistente IA del chat",
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: _analyzing ? null : _openAssistantOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_analyzing)
            LinearProgressIndicator(
              minHeight: 2,
              color: cs.primary,
              backgroundColor: cs.surfaceVariant,
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final esMio = _esMio(msg);

                final bubbleColor = esMio
                    ? cs.primary.withOpacity(0.15)
                    : cs.surfaceVariant;
                final textColor = cs.onSurface;

                return Align(
                  alignment: esMio
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(esMio ? 16 : 4),
                        bottomRight: Radius.circular(esMio ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: esMio
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!esMio)
                          Text(
                            msg["autor"] as String,
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (!esMio) const SizedBox(height: 2),
                        Text(
                          msg["text"] as String,
                          style: textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          msg["hora"] as String,
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      validateAliniDias(
                        context: context,
                        chatDay: ChatDay, // tu variable global
                        onAllowed:
                            _iniciarAliniVideoCall, // usa la función central
                      );
                    },
                    icon: Icon(Icons.videocam),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: cs.primary,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
