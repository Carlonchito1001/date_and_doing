import 'package:flutter/material.dart';
import 'dd_chat_page.dart';
import 'dd_mock_data.dart';

class DdMessages extends StatefulWidget {
  const DdMessages({super.key});

  @override
  State<DdMessages> createState() => _DdMessagesState();
}

class _DdMessagesState extends State<DdMessages> {
  final List<Map<String, dynamic>> _conversations =
      List<Map<String, dynamic>>.from(ddMockConversations);

  void _openChat(Map<String, dynamic> conversation) {
    final matchId = (conversation["matchId"] is int)
        ? conversation["matchId"] as int
        : int.tryParse(conversation["matchId"].toString()) ?? 0;

    final otherUserId = (conversation["otherUserId"] is int)
        ? conversation["otherUserId"] as int
        : int.tryParse((conversation["otherUserId"] ?? "0").toString()) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: matchId,
          otherUserId: otherUserId,
          nombre: conversation["nombre"] as String,
          foto: conversation["foto"] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final chat = _conversations[index];

            return ListTile(
              onTap: () => _openChat(chat),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(chat["foto"] as String),
              ),
              title: Text(
                chat["nombre"] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                chat["ultimoMensaje"] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chat["hora"] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  if ((chat["noLeidos"] as int) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "${chat["noLeidos"]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
