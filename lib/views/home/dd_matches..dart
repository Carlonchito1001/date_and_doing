import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/service/shared_preferences_service.dart';

import 'dd_chat_page.dart';

class DdMatches extends StatefulWidget {
  const DdMatches({super.key});

  @override
  State<DdMatches> createState() => _DdMatchesState();
}

class _DdMatchesState extends State<DdMatches> {
  final _api = ApiService();
  final _sp = SharedPreferencesService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accessToken = await _sp.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No hay access_token. Inicia sesión otra vez.');
      }

      final data = await _api.allMatches(accessToken: accessToken);

      if (!mounted) return;
      setState(() {
        matches = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ============== MAPEOS (tolerantes) ==============

  String _nameFrom(Map<String, dynamic> m) {
    // soporta: nombre, use_txt_fullname, user.fullname, match_user.fullname, etc.
    final v = m['nombre'] ??
        m['use_txt_fullname'] ??
        m['full_name'] ??
        m['fullname'] ??
        (m['user'] is Map ? (m['user']['use_txt_fullname'] ?? m['user']['fullname']) : null) ??
        (m['match_user'] is Map ? (m['match_user']['use_txt_fullname'] ?? m['match_user']['fullname']) : null);
    return (v ?? 'Usuario').toString();
  }

  int _ageFrom(Map<String, dynamic> m) {
    final v = m['edad'] ??
        m['age'] ??
        m['use_txt_age'] ??
        (m['user'] is Map ? m['user']['use_txt_age'] : null) ??
        (m['match_user'] is Map ? m['match_user']['use_txt_age'] : null);

    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _photoFrom(Map<String, dynamic> m) {
    final v = m['foto'] ??
        m['photo'] ??
        m['avatar'] ??
        m['use_txt_avatar'] ??
        (m['user'] is Map ? (m['user']['use_txt_avatar'] ?? m['user']['avatar']) : null) ??
        (m['match_user'] is Map ? (m['match_user']['use_txt_avatar'] ?? m['match_user']['avatar']) : null);

    final s = (v ?? '').toString();
    return s.isNotEmpty
        ? s
        : 'https://via.placeholder.com/600x900.png?text=DATE%20%26%20DOING';
  }

  String _statusKeyFrom(Map<String, dynamic> m) {
    final v = m['status'] ?? m['match_status'] ?? m['estado'] ?? m['online_status'];
    final s = (v ?? 'desconectado').toString().toLowerCase();
    return s;
  }

  Color _statusColor(String status) {
    switch (status) {
      case "nuevo":
        return Colors.pinkAccent;
      case "online":
        return Colors.green;
      case "activo":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case "nuevo":
        return "Nuevo Match 💖";
      case "online":
        return "En línea";
      case "activo":
        return "Activo";
      default:
        return "Desconectado";
    }
  }

  void _openChatFromMatch(Map<String, dynamic> match) {
    final nombre = _nameFrom(match);
    final foto = _photoFrom(match);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          nombre: nombre,
          foto: foto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus Matches'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Conexiones recientes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                "Toca un match para iniciar el chat ✨",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadMatches,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (matches.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Aún no tienes matches 🙌'),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    itemCount: matches.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final item = matches[index];

                      final nombre = _nameFrom(item);
                      final edad = _ageFrom(item);
                      final foto = _photoFrom(item);
                      final status = _statusKeyFrom(item);

                      return _MatchCard(
                        nombre: nombre,
                        edad: edad,
                        foto: foto,
                        statusText: _statusText(status),
                        statusColor: _statusColor(status),
                        onTap: () => _openChatFromMatch(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String nombre;
  final int edad;
  final String foto;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _MatchCard({
    super.key,
    required this.nombre,
    required this.edad,
    required this.foto,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 5,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: Image.network(foto, fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edad > 0 ? "$nombre, $edad" : nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
