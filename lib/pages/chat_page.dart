import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../model/message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _send(ChatProvider provider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat(ChatProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear chat'),
        content: const Text(
            '¿Seguro que deseas eliminar el historial de mensajes? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.resetChat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historial eliminado')),
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MenuBot - Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Resetear chat',
            onPressed: () => _resetChat(provider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];
                  final isUser = msg.sender == Sender.user;
                  return _buildMessageBubble(msg, isUser);
                },
              ),
            ),
            const Divider(height: 1),
            _buildInputArea(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isUser) {
    final bg = isUser ? Colors.blueAccent : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;

    final isThinking = msg.text.contains('Preparando respuesta');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _avatar(false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
              ),
              child: isThinking
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SpinKitThreeBounce(
                            size: 14, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          'Preparando respuesta...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    )
                  : Text(
                      msg.text,
                      style:
                          TextStyle(color: textColor, fontSize: 15),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(true),
        ],
      ),
    );
  }

  Widget _avatar(bool isUser) => CircleAvatar(
        radius: 16,
        backgroundColor:
            isUser ? Colors.blueAccent : Colors.grey.shade400,
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy,
          size: 18,
          color: Colors.white,
        ),
      );

  Widget _buildInputArea(ChatProvider provider) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(provider),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu pregunta sobre el menú...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            provider.isLoading
                ? const SpinKitThreeBounce(
                    size: 14, color: Colors.blueAccent)
                : IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () => _send(provider),
                  ),
          ],
        ),
      ),
    );
  }
}
