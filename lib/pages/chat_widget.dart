import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/agora_chat_service.dart';

class ChatWidget extends StatefulWidget {
  final String callId;
  final String userId;

  const ChatWidget({
    Key? key,
    required this.callId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isReadyToChat = false;
  bool _isConnected = true;

  late AgoraChatService _chatService;
  late String _displayUserId;

  @override
  void initState() {
    super.initState();
    _displayUserId = 'user_${Random().nextInt(10000)}';
    _initializeChat();
  }

  void _initializeChat() {
    if (!mounted) return;
    _chatService = Provider.of<AgoraChatService>(context, listen: false);

    // Configura i callback
    _chatService.onLogMessage = (message) {
      setState(() {
        _logs.add(message);
      });
      _scrollToBottom();
    };

    _chatService.onMessageReceived = (message) {
      setState(() {
        _logs.add(message);
      });
      _scrollToBottom();
    };

    _chatService.onLoginSuccess = () {
      setState(() {
        _isReadyToChat = true;
        _isConnected = true;
      });
    };

    _chatService.onLogout = () {
      setState(() {
        _isReadyToChat = false;
      });
    };

    // Inizializza il servizio chat
    _chatService.useCallId(widget.callId);
    _chatService.initialize(_displayUserId).catchError((error) {
      setState(() {
        _logs.add('Errore inizializzazione chat: $error');
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _addLog('Scrivi un messaggio');
      return;
    }

    if (!_isReadyToChat) {
      _addLog('Chat non ancora pronta. Attendi...');
      return;
    }

    _chatService.sendGroupMessage(message);
    _messageController.clear();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatService.logout(_displayUserId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: Column(
        children: [
          // Header della chat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Group Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID utente: $_displayUserId',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isReadyToChat
                          ? 'Connesso'
                          : (_isConnected ? 'Connettendo...' : 'Disconnesso'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Area messaggi
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: _logs.isEmpty
                  ? const Center(
                child: Text(
                  'Nessun messaggio ancora.\nScrivi qualcosa per iniziare!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final message = _logs[index];
                  final isOwnMessage = message.startsWith('You@');
                  final isSystemMessage = !message.contains('@') ||
                      message.startsWith('Connesso') ||
                      message.startsWith('Gruppo') ||
                      message.startsWith('Unito') ||
                      message.startsWith('Errore');

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: isSystemMessage
                          ? MainAxisAlignment.center
                          : (isOwnMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start),
                      children: [
                        if (!isSystemMessage)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isOwnMessage
                                    ? Colors.blue[100]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isOwnMessage
                                      ? Colors.blue[800]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          )
                        else
                          Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Area input messaggi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isReadyToChat,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isReadyToChat ? _sendMessage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Invia'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
