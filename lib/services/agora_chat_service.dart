import 'dart:convert';
import 'dart:math';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';

import 'js_interop.dart'; // Necessario per accedere a globalContext e utilizzare operatori dinamici



class AgoraChatService {
  static const String appKey = '711340750#1545482';
  static const String backendUrl = 'http://localhost:8082/chat';
  static const String groupUrl = 'http://localhost:8082/group';

  String _callId = '';
  String _createdGroupId = 'prova';

  // Callback per i messaggi e eventi
  Function(String message)? onMessageReceived;
  Function(String log)? onLogMessage;
  Function()? onLoginSuccess;
  Function()? onLogout;

  // Creare un'istanza della classe JavaScript
  final agoraChatClient = AgoraChatClient(appKey);


  /// Imposta il callId da utilizzare
  void useCallId(String callId) {
    _callId = callId;
    print('Call ID nel service: $_callId');
  }

  /// Inizializzazione dell'utente e creazione/join del gruppo predefinito
  Future<void> initialize(String userId) async {
    try {
      // 1. Genera un "groupname" casuale
      final randomName = (Random().nextDouble() * 9e15 + 1e15).toInt().toString();

      // 2. Crea il gruppo e prendi il vero groupId dalla risposta
      final createResp = await _createGroup(
        _callId,
        randomName,
        'Gruppo creato automaticamente',
        200,
        'admin',
      );

      print('Risposta da /group/create: $createResp');

      if (createResp['groupId'] == null) {
        _logMessage('Errore: impossibile creare il gruppo predefinito. Risposta: $createResp');
        return;
      }

      final groupId = createResp['groupId'] as String;
      _createdGroupId = groupId;
      _logMessage('Gruppo creato o già esistente con ID: $groupId');

      // 3. Registrazione e login dell'utente
      final loginResp = await _registerAndLogin(userId);
      if (loginResp['token'] == null) {
        _logMessage('Errore: token non ricevuto dal backend.');
        return;
      }

      final token = loginResp['token'] as String;

      // 4. Inizializza SDK Agora Chat
      final options = ChatOptions(
        appKey: appKey,
        autoLogin: false,
      );
      //il problema è qui, stampa un solo FUNZIONOOOOO

      //await ChatClient.getInstance.init(options);
      // Inizializzare la connessione
      agoraChatClient.init();

      // 5. Registra gli event handler
      ChatClient.getInstance.chatManager.addEventHandler(
        'chat_handler',
        ChatEventHandler(
          onMessagesReceived: (messages) {
            for (final message in messages) {
              if (message.body.type == MessageType.TXT && message.chatType == ChatType.GroupChat) {
                final txtBody = message.body as ChatTextMessageBody;
                final content = '${message.from}@${message.conversationId}: ${txtBody.content}';
                onMessageReceived?.call(content);
                _logMessage(content);
              }
            }
          },
        ),
      );


      ChatClient.getInstance.addConnectionEventHandler(
        'connection_handler',
        ConnectionEventHandler(
          onDisconnected: () {
            _logMessage('Disconnesso');
            onLogout?.call();
          },
          onConnected: () {
            _logMessage('Connesso come $userId');
          },
        ),
      );

      // 6. Login dell'utente

      //await ChatClient.getInstance.loginWithAgoraToken(userId, token);
      //_logMessage('Connesso come $userId');

      // Effettuare il login
      agoraChatClient.login(userId, 'accessToken');



      // 7. Unisciti al gruppo usando il vero groupId


      //await ChatClient.getInstance.groupManager.joinPublicGroup(groupId);
      //_logMessage('Unito al gruppo ID: $groupId');
      agoraChatClient.joinGroup(groupId);




      onLoginSuccess?.call();

    } catch (error) {
      _logMessage('Errore inizializzazione: $error');
      rethrow;
    }
  }

  /// Chiamata al backend per creare il gruppo se non esiste
  Future<Map<String, dynamic>> _createGroup(
      String callId,
      String name,
      String description,
      int maxUsers,
      String owner,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$groupUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'callId': callId,
          'name': name,
          'description': description,
          'maxUsers': maxUsers,
          'owner': owner,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('Risposta da /group/create: $data');

        if (data['groupId'] == null) {
          print('groupId mancante nella risposta: $data');
          return {};
        }

        return data;
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (err) {
      print('Errore creazione gruppo: $err');
      return {};
    }
  }

  /// Funzione per registrare e fare il login tramite il backend
  Future<Map<String, dynamic>> _registerAndLogin(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/register-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (err) {
      print('Errore durante la registrazione/login: $err');
      rethrow;
    }
  }



  Future<void> sendGroupMessage(String content) async {
    try {
      _logMessage('You@$_createdGroupId: $content');

      if (kIsWeb) {
        // Chiamata alla funzione JavaScript per la piattaforma web
        agoraChatClient.sendGroupMessage(_createdGroupId, content);
      } else {
        // Utilizzo del chatManager per piattaforme non web
        final message = ChatMessage.createTxtSendMessage(
          targetId: _createdGroupId,
          content: content,
        );
        message.chatType = ChatType.GroupChat;

        await ChatClient.getInstance.chatManager.sendMessage(message);
      }
    } catch (err) {
      _logMessage('Invio fallito: $err');
    }
  }


  /// Logout e cleanup temporaneo dell'utente
  Future<void> logout(String userId) async {
    try {
      await ChatClient.getInstance.logout(true);

      // Rimuovi gli event handler
      ChatClient.getInstance.chatManager.removeEventHandler('chat_handler');
      ChatClient.getInstance.removeConnectionEventHandler('connection_handler');

      // Se l'userId segue il pattern user_XXXX, cancellalo dal backend
      if (RegExp(r'^user_\d+$').hasMatch(userId)) {
        try {
          await http.post(
            Uri.parse('$backendUrl/delete-user'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId}),
          );
        } catch (err) {
          print('Errore cancellazione utente: $err');
        }
      }
    } catch (err) {
      print('Errore durante il logout: $err');
    }
  }

  void _logMessage(String message) {
    print(message);
    onLogMessage?.call(message);
  }
}

